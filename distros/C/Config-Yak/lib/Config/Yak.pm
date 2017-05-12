package Config::Yak;
{
  $Config::Yak::VERSION = '0.23';
}
BEGIN {
  $Config::Yak::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: a tree-based versatile config handler

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

use IO::Handle;
use autodie;

use Config::Any;
use Config::Tiny;
use Hash::Merge;
use Data::Dumper;
use Try::Tiny;
use Data::Structure::Util qw();

subtype 'ArrayRefOfStr',
     as 'ArrayRef[Str]';

coerce 'ArrayRefOfStr',
    from 'Str',
    via { [ $_ ] };

extends 'Data::Tree' => { -version => 0.16 };

has 'locations' => (
    'is'       => 'rw',
    'isa'      => 'ArrayRefOfStr',
    'coerce'   => 1,
    'required' => 1,
);

has 'last_ts' => (
    'is'      => 'rw',
    'isa'     => 'Num',
    'default' => 0,
);

has 'files_read' => (
    'is'    => 'rw',
    'isa'   => 'ArrayRef[Str]',
    'default' => sub { [] },
);

sub config {
    my $self = shift;
    my $arg  = shift;

    if ( defined($arg) ) {
        return $self->data($arg);
    }
    else {
        return $self->data();
    }
} ## end sub config

sub _init_debug {
    my $self = shift;

    if($ENV{'CONFIG_YAK_DEBUG'}) {
        return 1;
    }

    return 0;
}

############################################
# THIS METHOD IS NOT PART OF OUR PUBLIC API!
# Usage      :
# Purpose    :
# Returns    :
# Parameters :
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# THIS METHOD IS NOT PART OF OUR PUBLIC API!
sub _init_data {
    my $self = shift;

    # glob locations and conf.d dirs!
    my @files        = ();
    my @legacy_files = ();
    foreach my $loc ( @{ $self->locations() } ) {
        if ( -d $loc ) {
            foreach my $file ( glob( $loc . '/*.conf' ) ) {
                if ( $self->_is_legacy_config($file) ) {
                    push( @legacy_files, $file );
                }
                else {
                    push( @files, $file );
                }
            } ## end foreach my $file ( glob( $loc...))
            ## no critic (ProhibitMismatchedOperators)
            if ( -d $loc . '/conf.d' ) {
                ## use critic
                foreach my $file ( glob( $loc . '/conf.d/*.conf' ) ) {
                    if ( $self->_is_legacy_config($file) ) {
                        push( @legacy_files, $file );
                    }
                    else {
                        push( @files, $file );
                    }
                } ## end foreach my $file ( glob( $loc...))
            } ## end if ( -d $loc . '/conf.d')
        } ## end elsif ( -d $loc )
        elsif ( -e $loc ) {
            if ( $self->_is_legacy_config($loc) ) {
                push( @legacy_files, $loc );
            }
            else {
                push( @files, $loc );
            }
        } ## end if ( -e $loc )
    } ## end foreach my $loc ( @{ $self->locations...})
    ## no critic (RequireCheckedSyscalls)
    print '_init_config - glob()ed these files: ' . join( q{:}, @files ) . "\n" if $self->debug();
    print '_init_config - glob()ed these legacy files: ' . join( q{:}, @legacy_files ) . "\n" if $self->debug();
    ## use critic
    my $cfg = {};
    $cfg = $self->_load_legacy_config( [@legacy_files], $cfg );
    foreach my $file (@files) {
        $cfg = $self->_load_config( [$file], $cfg );
    }
    return $cfg;
} ## end sub _init_data

sub _is_legacy_config {
    my $self = shift;
    my $file = shift;

    my $is_legacy = 0;
    if ( -e $file && open( my $FH, '<', $file ) ) {
        my @lines = <$FH>;
        close($FH);
        foreach my $line (@lines) {
            if ( $line =~ m/^\[/ ) {    # ini-style config, old
                $is_legacy = 1;
                last;
            }
            elsif ( $line =~ m/^\s*</ ) {    # pseudo-XML config, new
                $is_legacy = 0;
                last;
            }
        } ## end foreach my $line (@lines)

    } ## end if ( -e $file && open(...))
    return $is_legacy;
} ## end sub _is_legacy_config

sub _load_legacy_config {
    my $self      = shift;
    my $files_ref = shift;
    my $cfg       = shift || {};

    Hash::Merge::set_behavior('RETAINMENT_PRECEDENT');
    foreach my $file ( @{$files_ref} ) {
        if ( -e $file ) {
            try {
                my $Config = Config::Tiny::->read($file);
                print '_load_legacy_config - Loaded ' . $file . "\n" if $self->debug();
                Data::Structure::Util::unbless($Config);
                $cfg = Hash::Merge::merge( $cfg, $Config );
                ## no critic (ProhibitMagicNumbers)
                my $last_ts = ( stat($file) )[9];
                ## use critic
                $self->last_ts($last_ts) if $last_ts > $self->last_ts();
                1;
            } ## end try
            catch {
                warn "Loading $file failed: $_\n" if $self->debug();
            };
        } ## end if ( -e $file )
    } ## end foreach my $file ( @{$files_ref...})
    return $cfg;
} ## end sub _load_legacy_config

sub _load_config {
    my $self      = shift;
    my $files_ref = shift;
    my $ccfg      = shift || {};

    ## no critic (ProhibitNoWarnings)
    no warnings 'once';
    ## no critic (ProhibitTwoArgOpen ProhibitBarewordFileHandles RequireBriefOpen ProhibitUnixDevNull)
    if(!$self->debug()) {
        open( OLD_STDERR, '>&STDERR' )
          or die('Failed to save STDERR');
        open( STDERR, '>', '/dev/null' )
          or die('Failed to redirect STDERR');
    }
    ## use critic
    my $cfg     = {};
    my $success = try {
        $cfg = Config::Any->load_files(
            {
                files       => $files_ref,
                use_ext     => 1,
                driver_args => {

                    # see http://search.cpan.org/~tlinden/Config-General-2.50/General.pm
                    General => {
                        -UseApacheInclude      => 0,
                        -IncludeRelative       => 0,
                        -IncludeDirectories    => 0,
                        -IncludeGlob           => 0,
                        -SplitPolicy           => 'equalsign',
                        -CComments             => 0,
                        -AutoTrue              => 1,
                        -MergeDuplicateBlocks  => 1,
                        -MergeDuplicateOptions => 0,
                        -LowerCaseNames        => 1,
                        -UTF8                  => 1,
                    },
                },
                flatten_to_hash => 1,
            },
        );
        1;
    } ## end try
    catch {
        print 'Loading ' . join( q{:}, @{$files_ref} ) . " failed: $_\n" if $self->debug();
    };
    return $ccfg unless $success;

    ## no critic (ProhibitTwoArgOpen)
    if(!$self->debug()) {
        open( STDERR, '>&OLD_STDERR' );
    }
    use warnings 'once';
    ## use critic
    Hash::Merge::set_behavior('RETAINMENT_PRECEDENT');

    # older versions of Config::Any don't know flatten_to_hash,
    # they'll always return an array of hashes, so we'll
    # transform them here
    if ( ref($cfg) eq 'ARRAY' ) {
        my $ncfg = {};
        foreach my $c ( @{$cfg} ) {
            foreach my $file ( keys %{$c} ) {
                $ncfg->{$file} = $c->{$file};
            }
        }
        $cfg = $ncfg;
    } ## end if ( ref($cfg) eq 'ARRAY')
    if ( ref($cfg) eq 'HASH' ) {
        foreach my $file ( keys %{$cfg} ) {
            print "_load_config - Loaded $file\n" if $self->debug();
            push(@{$self->files_read()},$file);
            $ccfg = Hash::Merge::merge( $ccfg, $cfg->{$file} );
            ## no critic (ProhibitMagicNumbers)
            my $last_ts = ( stat($file) )[9];
            ## use critic
            $self->last_ts($last_ts) if $last_ts > $self->last_ts();
        } ## end foreach my $file ( keys %{$cfg...})
    } ## end if ( ref($cfg) eq 'HASH')
    return $ccfg;
} ## end sub _load_config

############################################
# Usage      :
# Purpose    :
# Returns    :
# Parameters :
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
sub add_config {
    my $self = shift;
    my $file = shift;

    $self->config( Hash::Merge::merge( $self->config(), $self->_load_config( [$file] ) ) );
    return 1;
} ## end sub add_config

############################################
# Usage      :
# Purpose    :
# Returns    :
# Parameters :
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
sub reset_config {
    my $self = shift;

    $self->config( {} );

    return 1;
} ## end sub reset_config
## no critic (ProhibitBuiltinHomonyms)
sub dump {
    ## use critic
    my $self = shift;

    $Data::Dumper::Sortkeys = 1;
    return Dumper( $self->config() );
} ## end sub dump

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Config::Yak - a tree-based versatile config handler

=head1 SYNOPSIS

    use Config::Yak;

    my $cfg = Config::Yak::->new({ locations => [qw(/etc/foo)]});
    ...

=head1 METHODS

=head2 add_config

Parse another config file.

=head2 config

Get the whole config as an HashRef

=head2 dump

Stringify the whole config w/ Data::Dumper;

=head2 reset_config

Delete all configuration items.

=head1 NAME

Config::Yak - Data::Tree based config handling

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
