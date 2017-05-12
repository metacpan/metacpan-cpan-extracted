package CPAN::Mini::Visit::Simple;
use 5.010;
use strict;
use warnings;

our $VERSION = '0.015';
$VERSION = eval $VERSION; ## no critic

use Archive::Extract;
use Carp;
use CPAN::Mini ();
use Cwd;
use File::Basename qw( dirname basename );
use File::Find;
use File::Spec;
use File::Temp;
use Path::Class;
use Scalar::Util qw( reftype );
use CPAN::Mini::Visit::Simple::Auxiliary qw(
    $ARCHIVE_REGEX
    dedupe_superseded
    get_lookup_table
    normalize_version_number
);

sub new {
    my ($class, $args) = @_;
    my %data = ();
    if ( ! $args->{minicpan} ) {
        # Work around a bug in CPAN::Mini:
        # https://rt.cpan.org/Public/Bug/Display.html?id=55272
        my $config_file = CPAN::Mini->config_file({});
        croak "CPAN::Mini config file not located: $!"
            unless ( defined $config_file and -e $config_file );
        my %config = CPAN::Mini->read_config;
        if (  $config{local} ) {
            $data{minicpan} = $config{local};
        }
    }
    else {
        $data{minicpan} = $args->{minicpan};
    }
    croak "Directory $data{minicpan} not found"
        unless (-d $data{minicpan});

    my $id_dir = File::Spec->catdir($data{minicpan}, qw( authors id ));
    croak "Absence of $id_dir implies no valid minicpan"
        unless -d $id_dir;
    $data{id_dir} = $id_dir;

    my $self = bless \%data, $class;
    return $self;
}

sub get_minicpan {
    my $self = shift;
    return $self->{minicpan};
}

sub get_id_dir {
    my $self = shift;
    return $self->{id_dir};
}
sub identify_distros {
    my ($self, $args) = @_;

    croak "Bad argument 'list' provided to identify_distros()"
        if exists $args->{list};

    if ( defined $args->{start_dir} ) {
        croak "Directory $args->{start_dir} not found"
            unless (-d $args->{start_dir} );
        croak "Directory $args->{start_dir} must be subdirectory of $self->{id_dir}"
            unless ( $args->{start_dir} =~ m/\Q$self->{id_dir}\E/ );
        $self->{start_dir} = $args->{start_dir};
    }
    else {
        $self->{start_dir} = $self->{id_dir};
    }

    if ( defined $args->{pattern} ) {
        croak "'pattern' is a regex, which means it must be a REGEXP ref"
            unless (reftype($args->{pattern}) eq 'REGEXP');
    }

    my $found_ref = $self->_search_from_start_dir( $args );
    $self->{list} = dedupe_superseded( $found_ref );
    return 1;
}

sub identify_distros_from_derived_list {
    my ($self, $args) = @_;
    croak "Bad argument 'start_dir' provided to identify_distros_from_derived_list()"
        if exists $args->{start_dir};
    croak "Bad argument 'pattern' provided to identify_distros_from_derived_list()"
        if exists $args->{pattern};
    croak "identify_distros_from_derived_list() needs 'list' element"
        unless exists $args->{list};
    croak "Value of 'list' must be array reference"
        unless reftype($args->{list}) eq 'ARRAY';
    croak "Value of 'list' must be non-empty"
        unless scalar(@{$args->{list}});
    $self->{list} = dedupe_superseded( $args->{list} );
    return 1;
}

sub _search_from_start_dir {
    my ($self, $args) = @_;
    my @found = ();
    find(
        {
            follow => 0,
            no_chdir => 1,
            preprocess => sub { my @files = sort @_; return @files },
            wanted => sub {
                return unless /$ARCHIVE_REGEX/;
                if ( defined $args->{pattern} ) {
                    return unless $_ =~ m/$args->{pattern}/;
                }
                push @found, File::Spec->canonpath($File::Find::name);
            },
        },
        $self->{start_dir},
    );
    return \@found;
}

sub say_list {
    my ($self, $args) = @_;
    if (not defined $args) {
        say $_ for @{$self->{list}};
    }
    else {
        croak "Argument must be hashref" unless reftype($args) eq 'HASH';
        croak "Need 'file' element in hashref" unless exists $args->{file};
        open my $FH, '>', $args->{file}
            or croak "Unable to open handle to $args->{file} for writing";
        say $FH $_ for @{$self->{list}};
        close $FH
            or croak "Unable to close handle to $args->{file} after writing";
    }
}

sub get_list {
    my ($self) = @_;
    return unless defined $self->{list};
    return @{$self->{list}};
}

sub get_list_ref {
    my ($self) = @_;
    return unless defined $self->{list};
    return $self->{list};
}

sub refresh_list {
    my ($self, $args) = @_;
    croak "Need 'derived_list' whose value is list of distributions needing refreshment"
        unless exists $args->{derived_list};
    croak "Value of 'derived_list' must be array reference"
        unless reftype( $args->{derived_list} ) eq 'ARRAY';

    # Call identify_distros() with all arguments except 'derived_list',
    # i.e., with 'start_dir' and/or 'pattern'.
    my %reduced_args = map { $_ => 1 } @{ $args->{derived_list} };
    delete $reduced_args{derived_list};
    my $rv = $self->identify_distros( \%reduced_args );

    # So now we have an updated primary list ($self->{list}).
    # We will need to make a hash out of that where they key is the stem of
    # the distribution name and the value is the version.
    # We will make a similar hash from the derived list.

    my $primary = get_lookup_table( $self->get_list_ref() );
    my $derived = get_lookup_table( $args->{derived_list} );

    foreach my $stem ( keys %{$derived} ) {
        if ( not exists $primary->{$stem} ) {
            delete $derived->{$stem};
        }
        elsif ( $primary->{$stem}{version} > $derived->{$stem}{version} ) {
            $derived->{$stem}{version} = $primary->{$stem}{version};
            $derived->{$stem}{distro} = $primary->{$stem}{distro};
        }
        else {
            # nothing to do
        }
    }

    return [ sort map { $derived->{$_}{distro} } keys %{$derived} ];
}

sub visit {
    my ($self, $args) = @_;
    no warnings 'once';
    local $Archive::Extract::PREFER_BIN = 1;
    use warnings 'once';
    local $Archive::Extract::WARN = $args->{quiet} ? 0 : 1;
    croak "Must have a list of distributions on which to take action"
        unless defined $self->{list};
    croak "'visit()' method requires 'action' subroutine reference"
        unless (
            ( defined ($args->{action}) )
                and
            ( defined reftype($args->{action}) )
                and
            ( reftype($args->{action}) eq 'CODE' )
        );
    my @action_args = ();
    if ( defined $args->{action_args} ) {
        croak "'action_args' must be array reference"
            unless (
                ( defined reftype($args->{action_args}) )
                    and
                ( reftype($args->{action_args}) eq 'ARRAY' )
            );
        @action_args = @{ $args->{action_args} };
    }
    my $here = cwd();
    LIST: foreach my $distro ( @{$self->{list}} ) {
        my $proper_distro = q{};
        my $real_id_dir = $self->get_id_dir();
        if ( $distro =~ m|\Q$real_id_dir\E| ) {
            $proper_distro = basename($distro);
        }

        my $olderr;
        # stderr > /dev/null if quiet
        if ( not  $Archive::Extract::WARN ) {
            open $olderr, ">&STDERR";
            open STDERR, ">", File::Spec->devnull;
        }
        my $tdir = File::Temp->newdir();
        chdir $tdir or croak "Unable to change to temporary directory";
        my $ae = Archive::Extract->new( archive => $distro );
        my $extract_ok = $ae->extract( to => $tdir ) or do {
            warn "Unable to extract $distro; skipping";
            if ( not $Archive::Extract::WARN ) {
                open STDERR, ">&", $olderr;
                close $olderr;
            }
            next LIST;
        };

        # restore stderr if quiet
        if ( not $Archive::Extract::WARN ) {
            open STDERR, ">&", $olderr;
            close $olderr;
        }
        # Note:  It's not clear what would cause $extract_ok to be false.
        # Things that are not valid archives appear to be caught by
        # Archive::Extract::new() and rendered as fatal.  So following block
        # is unlikely to be covered by test suite.
        if ( ( not $extract_ok ) and  $Archive::Extract::WARN ) {
            carp "Couldn't extract '$distro'";
            return;
        }
        # most distributions unpack a single directory that we must enter
        # but some behave poorly and unpack to the current directory
        my $dir = Path::Class::Dir->new();
        my @children = $dir->children;
        if ( ( @children == 1 ) and ( -d $children[0] ) ) {
          chdir $children[0];
        }

        &{$args->{action}}($proper_distro, @action_args);# execute command
        chdir $here or croak "Unable to change back to starting point";
    }
    return 1;
}

1;
