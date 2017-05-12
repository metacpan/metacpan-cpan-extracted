package BFD;

$VERSION = 0.31;

=head1 NAME

  BFD - Impromptu dumping of data structures for debugging purposes

=head1 SYNOPSIS

   my $scary_structure1 = foo();
   my $scary_structure2 = bar();
   use BFD; d $scary_structure1, " hmmm ", $scary_structure2, ...;
   ....

=head1 DESCRIPTION

Allows for impromptu dumping of output to STDERR.  Useful when you want
to take a peek at a nest Perl data structure by emitting (relatively)
nicely formatted output with filename and line number prefixed to each line.

Basically,

    use BFD;d $foo;

is shorthand for

    use Data::Dumper;
    local $Data::Dumper::Indent    = 1;
    local $Data::Dumper::Quotekeys = 0;
    local $Data::Dumper::Terse     = 1;
    local $Data::Dumper::Sortkeys  = 1;
    my $msg = Dumper( $foo );
    $msg =~ s/^/$where: /mg;
    warn $msg;

I use this incantation soooo often that a TLA version is warranted.
YMMV.

=cut

use strict;
use Cwd qw( cwd );
use File::Spec;

sub import {
    no strict 'refs';
    *{caller() . "::d"} = \&d;
}


sub dump_ref {
    require Data::Dumper;
    local $Data::Dumper::Indent    = 1;
    local $Data::Dumper::Quotekeys = 0;
    local $Data::Dumper::Terse     = 1;
    local $Data::Dumper::Sortkeys  = 1;
    Data::Dumper::Dumper( @_ )
}


my $start_dir;  ## Captured at compile time to use for shortening prefixes
BEGIN {
    $start_dir = cwd;
};

use vars qw( $LineNumberWidth );

$LineNumberWidth = 4;

sub format_msg {
    my ( $fn, $ln ) = ( shift, shift );

    ## Line number fields never get narrower so that you don't
    ## get output that's all jaggy.
    $LineNumberWidth = length $ln if length $ln > $LineNumberWidth;

    if ( File::Spec->file_name_is_absolute( $fn ) ) {
        if ( $fn =~ s/.*\b(site_perl)\b/$1/ ) {
            ## Should use Config.pm's list of perl dirs, but hack for now
        }
        else {
            my $rel_fn = File::Spec->abs2rel( $fn, $start_dir );
            if ( 0 == index $rel_fn, File::Spec->updir ) {
                $fn = $rel_fn;
            }
        }
    }


    my $where = sprintf "%s, %${LineNumberWidth}d:", $fn, $ln;

    my $msg = join "", map {
        ( my $out = $_ ) =~ s/^/$where/gm;
        $out;
    } join "", map
        ! defined $_ ? "undef"
        : ref $_     ? dump_ref $_
                     : $_,
    @_;

    1 while chomp $msg;
    return $msg;
}


sub d {
    warn format_msg( (caller)[1,2], @_ );
}


sub d_to {
    my $fh = shift;
    print $fh format_msg( (caller)[1,2], @_ );
}


sub d_to_string {
    format_msg( (caller)[1,2], @_ );
}


=head1 LIMITATIONS

Uses Data::Dumper, which has varying degrees of stability and usefulness
on different versions of perl.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=head1 COPYRIGHT

Copyright (c) 2003, Barrie Slaymaker.  All Rights Reserved.

=head1 LICENSE

You may use this software under the terms of the GNU Public License, the
Artistic License, the BSD license, or the MIT license.

Good luck and God Speed.

=cut

1 ;
