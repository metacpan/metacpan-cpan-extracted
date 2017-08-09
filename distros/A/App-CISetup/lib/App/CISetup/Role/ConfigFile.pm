package App::CISetup::Role::ConfigFile;

use strict;
use warnings;
use namespace::autoclean;
use autodie qw( :all );

our $VERSION = '0.07';

use App::CISetup::Types qw( Path );
use Try::Tiny;
use YAML qw( Dump LoadFile );

use Moose::Role;

requires qw(
    _cisetup_flags
    _create_config
    _fix_up_yaml
    _update_config
);

has file => (
    is       => 'ro',
    isa      => Path,
    coerce   => 1,
    required => 1,
);

sub create_file {
    my $self = shift;

    $self->file->spew( $self->_config_to_yaml( $self->_create_config ) );

    return;
}

sub update_file {
    my $self = shift;

    my $file = $self->file;
    my $orig = $file->slurp;

    my $content = try {
        LoadFile($file);
    }
    catch {
        die "YAML parsing error: $_\n";
    };

    return 0 unless $content;

    my $config = $self->_update_config($content);
    my $yaml   = $self->_config_to_yaml($config);

    return 0 if $yaml eq $orig;

    $file->spew($yaml);

    return 1;
}

sub _config_to_yaml {
    my $self   = shift;
    my $config = shift;

    ## no critic (TestingAndDebugging::ProhibitNoWarnings, Variables::ProhibitPackageVars)
    no warnings 'once';

    # If Perl versions aren't quotes then Travis displays 5.10 as "5.1"
    local $YAML::QuoteNumericStrings = 1;
    my $yaml = Dump($config);
    $yaml = $self->_fix_up_yaml($yaml);

    return $self->_fix_up_yaml($yaml) . $self->_cisetup_flags_as_comment;
}

sub _cisetup_flags_as_comment {
    my $self = shift;

    my $yaml = Dump( $self->_cisetup_flags );
    $yaml =~ s/^/# /gm;

    # Yes, this is YAML embedded in YAML as a comment. Yes, this is dumb. Yes,
    # this is necessary. Unfortunately, AppVeyor chokes on random keys in its
    # config file, so we have no choice but to use a comment. We could use
    # Data::Dumper but we're already using YAML, and I don't really love doing
    # an "eval" when trying to read this data.
    return sprintf( <<'EOF', $yaml );
### __app_cisetup__
%s
### __app_cisetup__
EOF
}

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _reorder_yaml_blocks {
    my $self         = shift;
    my $yaml         = shift;
    my $blocks_order = shift;

    my $re = qr/^
                (
                    ([a-z_]+): # key:
                    (?:
                        (?:$)\n.+?
                    |
                        \ .+?\n
                    )
                )
                (?=^[a-z]|\z)
               /xms;

    my %blocks;
    while ( $yaml =~ /$re/g ) {
        $blocks{$2} = $1;
    }

    for my $name ( keys %blocks ) {
        my $method = '_reorder_' . $name . '_block';
        next unless $self->can($method);
        $blocks{$name} = $self->$method( $blocks{$name} );
    }

    my %known_blocks = map { $_ => 1 } @{$blocks_order};
    for my $block ( keys %blocks ) {
        die "Unknown block $block in " . $self->file
            unless $known_blocks{$block};
    }

    return "---\n" . join q{}, map { $blocks{$_} // () } @{$blocks_order};
}
## use critic

1;
