#Copyright (c) 2010 Joachim Bargsten <code at bargsten dot org>. All rights reserved.

package Bio::Gonzales::Util::YAML;

use warnings;
use strict;
use Carp;

use 5.010;

use YAML::XS;
use parent 'YAML::XS';
our ( @EXPORT, @EXPORT_OK, %EXPORT_TAGS );
our $VERSION = '0.0546'; # VERSION

carp "Bio::Gonzales::Util::YAML is deprecated, use Bio::Gonzales::Util::Cerial instead";


=head1 NAME

Bio::Gonzales::Util::YAML - convenience functions for yaml storage

=head1 SYNOPSIS

    use Bio::Gonzales::Util::YAML;

    my $yaml_string = freeze \%data;
    my $data = thaw $yaml_string;

    freeze_file $filename, \%data ;
    my $data = thaw_file $filename;

=head1 DESCRIPTION
    
    Bio::Gonzales::Util::YAML provides some handy functions to work with yaml data

=head1 EXPORT

=head2 $yaml_string = freeze($data,...);

=head2 $data = thaw($yaml_string);

=head2 freeze_file($filename, $data, ...);

=head2 $data = thaw_file($filename);

=cut

@EXPORT = qw(thaw freeze thaw_file freeze_file yslurp yspew);

{
    no warnings 'once';
    # freeze/thaw is the API for Storable string serialization. Some
    # modules make use of serializing packages on if they use freeze/thaw.
    *freeze = \&YAML::XS::Dump;
    *thaw   = \&YAML::XS::Load;
}

sub yslurp { return thaw_file(@_) }
sub yspew { return freeze_file(@_) }

sub freeze_file {
    my $OUT;
    my $filename = shift;
    if ( ref $filename eq 'GLOB' ) {
        $OUT = $filename;
    } else {
        my $mode = '>';
        if ( $filename =~ /^\s*(>{1,2})\s*(.*)$/ ) {
            ( $mode, $filename ) = ( $1, $2 );
        }
        open $OUT, $mode, $filename
            or die( join( "\n", 'YAML_DUMP_ERR_FILE_OUTPUT', $filename, $! ) );
    }
    binmode $OUT, ':utf8';    # if $Config{useperlio} eq 'define';
    local $/ = "\n";          # reset special to "sane"
    print $OUT freeze(@_);
}

sub thaw_file {
    my $IN;
    my $filename = shift;
    if ( ref $filename eq 'GLOB' ) {
        $IN = $filename;
    } else {
        open $IN, '<', $filename
            or die( join( "\n", 'YAML_LOAD_ERR_FILE_INPUT', $filename, $! ) );
    }
    binmode $IN, ':utf8';    # if $Config{useperlio} eq 'define';
    return thaw(
        do { local $/; <$IN> }
    );
}

1;
__END__

=head1 SEE ALSO

=head1 AUTHOR

jw bargsten, C<< <joachim.bargsten at wur.nl> >>

=cut
