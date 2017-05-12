package App::BoolFindGrep::Find;

use common::sense;
use charnames q(:full);
use Carp;
use English qw[-no_match_vars];
use File::Find;
use IO::File;
use Moo;
use Text::Glob qw[glob_to_regex_string];

our $VERSION = '0.06'; # VERSION

has files_from => (
    is  => q(rw),
    isa => sub {
        (          ( -e $_[0] && -r $_[0] && -f $_[0] && -s $_[0] )
                || ( $_[0] eq q(-) || $_[0] =~ /\Astdin\z/i ) )
            || die;
    }
);
has files_delim => (
    is      => q(rw),
    default => undef,
);
has file_expr => (
    is      => q(rw),
    isa     => sub { die if @_ > 1; die if ref $_[0]; },
    default => undef,
);
has find_type => (
    is  => q(rw),
    isa => sub {
        ( grep { $_[0] eq $_ } qw[glob literal regexp] ) > 0 or die;
    },
    default => q(regexp),
);
has find_ignore_case => (
    is      => q(rw),
    isa     => sub { ( $_[0] == 0 || $_[0] == 1 ) or die; },
    default => 0,
);
has directory => (
    is  => q(rw),
    isa => sub {
        @{ $_[0] } == ( grep { -d $_ && -r $_ } @{ $_[0] } ) or die;
    },
    default => sub { [q(.)] },
);
has patterns => ( is => q(rw), default => sub { {}; }, );
has found    => ( is => q(rw), default => sub { {}; }, );
has files    => ( is => q(rw), default => sub { []; }, );

sub process {
    my $self = shift;

    die if defined $self->files_delim() && !( defined $self->files_from() );
    die if defined $self->files_from()  && defined $self->file_expr();
    die
        if defined $self->files_from()
        && @{ $self->directory() } != 1
        && $self->directory->[0] ne q(.);

    if ( defined $self->files_from() ) {
        $self->_get_made_list();
    }
    else { $self->_finder(); }

    return 1;
} ## end sub process

sub _get_made_list {
    my $self = shift;

    local $INPUT_RECORD_SEPARATOR = $self->files_delim();

    my $fh
        = $self->files_from() =~ /\A(?:-|stdin)\z/i
        ? \*STDIN
        : IO::File->new( $self->files_from(), q(r) );

    while ( my $file = readline $fh ) {
        chomp $file;
        croak sprintf q('%s': irregular file.), $file if !-f $file;
        push @{ $self->files() }, $file;
    }

    return 1;
} ## end sub _get_made_list

sub _finder {
    my $self = shift;

    unless ( defined $self->file_expr() ) {
        find sub { push @{ $self->files() }, $File::Find::name if -f },
            @{ $self->directory() };
    }

    $self->_process_patterns();

    find sub {
        if ( -f $_ ) {
            if ( %{ $self->patterns() } ) {
                foreach my $pattern ( keys %{ $self->patterns() } ) {
                    my $re = $self->patterns->{$pattern};
                    $self->found->{$File::Find::name}{$pattern} //= 0;
                    $self->found->{$File::Find::name}{$pattern}++ if m{$re};
                }
            }
        }
    }, @{ $self->directory() };

    return 1;
} ## end sub _finder

sub _process_patterns {
    my $self = shift;

    foreach my $pattern ( keys %{ $self->patterns() } ) {
        my $value = $pattern;
        foreach ( $self->find_type() ) {
            if ( $_ eq q(literal) ) { $value = quotemeta $value; }
            elsif ( $_ eq q(glob) ) {
                $value = glob_to_regex_string($value);
                $value.= q(\z);
            }
        }
        $value = $self->find_ignore_case() == 1 ? qr{$value}i : qr{$value};
        $self->patterns->{$pattern} = $value;
    }

    return 1;
} ## end sub _process_patterns

no Moo;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::BoolFindGrep::Find - search for files in a directory hierarchy.

=head1 VERSION

version 0.06

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 file_expr

Scalar with original expression.

=head2 files

Array reference with list of files found.

=head2 files_delim

Scalar with string delimiter of a file list.

=head2 found

Hash reference that stores parsing results.

=head2 patterns

Hash reference with original operands and processed operands.

=head2 process

Does the work.

=head1 OPTIONS

=head1 ERRORS

=head1 DIAGNOSTICS

=head1 EXAMPLES

=head1 ENVIRONMENT

=head1 FILES

=head1 CAVEATS

=head1 BUGS

=head1 RESTRICTIONS

=head1 NOTES

=head1 AUTHOR

Ronaldo Ferreira de Lima aka jimmy <jimmy at gmail>.

=head1 HISTORY

=head1 SEE ALSO
