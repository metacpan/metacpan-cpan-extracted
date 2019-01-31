package App::iperlmoddir::Utils;
$App::iperlmoddir::Utils::VERSION = '1.0';
use strict;
use warnings;
use feature 'say';

use Module::Info;
use Module::Metadata;

# use Module::Load;
use Module::Util qw(module_path);

use File::Basename;
use List::Compare;
use List::Util qw(max uniq);
use List::MoreUtils qw(each_arrayref);
use Package::Constants;
use Carp;

use Data::Dump qw(dd);

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
  get_inspected_modules_list
  parse_modules
  _extract_base
  _validate_module_fullname
  _substr_aldc
  _cols2rows
  _sort_cols_AoA_by_neighbour
  _rm_header_from_cols_AoA
  _add_header_to_cols_AoA
);
our %EXPORT_TAGS = ( 'all' => [@EXPORT_OK] );


sub get_inspected_modules_list {
    my ( $dir, $exclude_list, $v ) = @_;

    say "Inspecting modules in " . $dir if $v;
    say "Skip modules : " . join( ',', @$exclude_list )
      if ( $v && @$exclude_list );

    opendir( my $dh, $dir ) or die $!;

    my @files;
    while ( my $file = readdir($dh) ) {
        next unless ( -f "$dir/$file" );
        next unless ( $file =~ m/\.pm$/ );

        # $file=~ s/(\w+).pm/$1/;
        push @files, $file;
    }
    closedir($dh);

    my $lc = List::Compare->new( \@files, $exclude_list );
    return $lc->get_Lonly_ref;
}

sub _substr_aldc {
    my ($str) = @_;
    return if !defined $str;
    my @x = split( '::', $str );
    return $x[-1];
}

sub _extract_base {
    my (%p) = @_;

# https://stackoverflow.com/questions/7283274/check-whether-a-string-contains-a-substring
    if ( index( $p{abs}, $p{rel} ) == -1 ) {
        croak "Relative path "
          . $p{rel}
          . " is not part of full path "
          . $p{abs}
          . ", maybe corresponded module placed in wrong dir";
    }

    my $to_rel_idx = length( $p{abs} ) - length( $p{rel} ) - 1;
    substr $p{abs}, 0, $to_rel_idx;
}

sub _validate_module_fullname {
    my ($fullname) = @_;
    my ( $name, $path, $suffix ) = fileparse( $fullname, 'pm' );

    carp
      "Provided module name ($fullname) contain path so results may not correct"
      if ( $path ne './' );

# croak "Provided module name ($fullname) is not perl module" if ( $suffix ne 'pm' );
    return 0 if ( $suffix ne 'pm' );

    return $name . $suffix;
}


sub parse_modules {
    my ($files) = @_;

    my @res = ();
    for my $f ( sort @$files ) {

        _validate_module_fullname($f);

        my $info         = Module::Metadata->new_from_file($f);
        my $name         = $info->name;
        my $abs_filename = $info->filename;
        my $rel_filename = module_path $name;

        eval {
            my $inc =
              _extract_base( abs => $abs_filename, rel => $rel_filename );
            push @INC, $inc;
            1;
        } or do {
            say "Module $name skipped from analysis. Exception : " . $@;
            next;
        };

        # Package::Constants need module to be loaded
        require $f;

        # or autoload $name;

        my $mod  = Module::Info->new_from_loaded($name);
        my %subs = $mod->subroutines;
        my @used = sort { "\L$a" cmp "\L$b" } $mod->modules_used;

        my @consts = Package::Constants->list($name);
        push @res,
          {
            name => $name,
            subs =>
              [ map { _substr_aldc $_ } sort { "\L$a" cmp "\L$b" } keys %subs ],
            used   => \@used,
            consts => [ sort { "\L$a" cmp "\L$b" } @consts ]
          };

    }

    return \@res;
}

sub _cols2rows {
    my ($colls_arr) = @_;

    my @sizes;
    my @rows;

    for my $max_idx (@$colls_arr) {
        push @sizes, $#$max_idx;
    }

    for my $i ( 0 .. $#$colls_arr ) {
        for my $j ( 0 .. max @sizes ) {
            $rows[$j][$i] = _substr_aldc( $colls_arr->[$i][$j] );
        }
    }

    return \@rows;
}

sub _add_header_to_cols_AoA {
    my ( $AoA, $header ) = @_;

    croak "Different size of header and table rows amount"
      if ( $#$AoA != $#$header );

    my $ea = each_arrayref( $AoA, $header );
    while ( my ( $a, $b ) = $ea->() ) {
        unshift @$a, $b;
    }

    return $AoA;
}

sub _rm_header_from_cols_AoA {
    my ($AoA) = @_;

    my @header;
    for my $col (@$AoA) {
        push @header, $col->[0];
        shift @$col;
    }
    return \@header;
}

# See more
# https://stackoverflow.com/questions/54333145/sort-table-or-2-dimensional-array-by-same-values-in-column
# https://perldoc.pl/perllol

sub _sort_cols_AoA_by_neighbour {
    my ( $data, $has_header ) = @_;

    # if first element is column header start idx = 1
    my $i = ( $has_header ? 1 : 0 );
    my @all;

    for my $col_arr (@$data) {
        push @all, @$col_arr[ $i .. $#$col_arr ];
    }

    my $header = _rm_header_from_cols_AoA($data) if $has_header;
    @all = sort { "\L$a" cmp "\L$b" } grep { $_ } uniq @all;

    for my $ary (@$data) {

        my $cmp_at = 0;
        my @res;
        for my $i ( 0 .. $#all ) {

            if ( !defined $ary->[$cmp_at] ) {
                push @res, undef;
            }
            elsif ( $ary->[$cmp_at] eq $all[$i] ) {
                push @res, $ary->[$cmp_at];
                ++$cmp_at;
            }
            else {
                push @res, undef;
            }
        }
        $ary = \@res;
    }

    _add_header_to_cols_AoA( $data, $header ) if $has_header;

    return $data;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::iperlmoddir::Utils

=head1 VERSION

version 1.0

=head1 get_inspected_modules_list

Get list of perl modules (files with .pm extension ) in particular dir

Do not parse subdirectories

Return list of files without .pm ending

TO-DO: pass 'GLOB' for convenient unit testing or use Dir::ls
z

=head1 parse_modules

Parse modules using L<Module::Info> (no L<Class::Inspector>)

Return list, each element is hash with following keys: 
name, subs, used, consts

Keys subs, used, consts store arrayref

$files are always without basepath

=head1 AUTHOR

Pavel Serikov <pavelsr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
