package App::mycnfdiff::Utils;
$App::mycnfdiff::Utils::VERSION = '1.00';
use strict;
use warnings;
use feature 'say';
use Carp;

use List::Compare;
use List::Util qw(uniq);
use Config::MySQL::Reader;

use Data::Dump qw(dd);
use Data::Dumper;

use Const::Fast;
const my $ALLOWED_EXTENSIONS_REGEX => qr/\.ini|cnf$/;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
  get_folder
  get_configs
  compare
  split_compare_hash
);
our %EXPORT_TAGS = ( 'all' => [@EXPORT_OK] );

#Process skip files, filter extensions and return pwd-ed path

sub get_folder {
    my (%opts) = @_;

    say "Inspecting modules in " . $opts{'dir'} if $opts{'v'};
    say "Skip files : " . join( ',', @{ $opts{'skip'} } )
      if ( $opts{'v'} && @{ $opts{'skip'} } );

    my @files;
    opendir( my $dh, $opts{'dir'} ) or die $!;
    while ( my $file = readdir($dh) ) {

        # warn $file;
        next unless ( -f $opts{'dir'} . '/' . $file );
        next unless ( $file =~ m/$ALLOWED_EXTENSIONS_REGEX/ );
        push @files, $opts{'dir'} . '/' . $file;
    }
    closedir($dh);

    my $lc = List::Compare->new( \@files, $opts{'skip'} );
    return $lc->get_Lonly;
}


sub get_configs {
    my (%opts) = @_;

    my $result = {};

    if ( @{ $opts{'include_only'} } ) {
        for my $filename ( @{ $opts{'include_only'} } ) {

            # to-do: resolve compiled defaults exec: tag
            # _detect_compiled_defaults_format
            $result->{$filename} = Config::MySQL::Reader->read_file($filename);
        }
    }
    else {
        my @files = get_folder(%opts);
        $result->{$_} = Config::MySQL::Reader->read_file($_) for (@files);
    }

    warn Dumper $result;

    return $result;
}

# Return value if all hash values are same and

sub _try_group_hash {
    my %x      = @_;
    my @values = uniq values %x;
    return $values[0] if ( scalar @values == 1 );
    my $result;
    while ( my ( $key, $value ) = each(%x) ) {
        $result->{$key} = $value;
    }
    return $result;
}

sub compare {
    my ($h) = @_;

    my @filenames               = keys %$h;
    my @all_possible_ini_groups = uniq map { keys %$_ } values %$h;

    my $result;
    for my $group_name (@all_possible_ini_groups) {
        $result->{$group_name} =
          [ uniq map { keys %{ $h->{$_}{$group_name} } } @filenames ];
        my $temp = {};

        for my $param ( @{ $result->{$group_name} } ) {
            my %values = map { $_ => $h->{$_}{$group_name}{$param} } @filenames;
            $temp->{$param} = _try_group_hash(%values);
        }

        $result->{$group_name} = $temp;
    }

    return $result;
}

# if group_key->param_key->val = scalar push to same key, otherwise to diff

sub split_compare_hash {
    my ($hash) = @_;

    my $res = {
        same => {},
        diff => {}
    };

    while ( my ( $group_name, $group_params ) = each(%$hash) ) {

        my ( $group_same, $group_diff ) = {};
        while ( my ( $param, $val ) = each(%$group_params) ) {

            if ( ref $val eq '' ) {
                $group_same->{$param} = $val;
            }
            else {
                $group_diff->{$param} = $val;
            }
        }

        $res->{same}{$group_name} = $group_same if (%$group_same);
        $res->{diff}{$group_name} = $group_diff if (%$group_diff);

    }
    return $res;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::mycnfdiff::Utils

=head1 VERSION

version 1.00

=head1 get_configs

Get content of configs into hash using L<Config::MySQL::Reader>

Resolve `exec:` tag in case of compiled defaults source using get_cd()

=head1 AUTHOR

Pavel Serikov <pavelsr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
