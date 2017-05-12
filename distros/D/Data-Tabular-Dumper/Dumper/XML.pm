# $Id: XML.pm 456 2009-04-15 12:20:59Z fil $
package Data::Tabular::Dumper::XML;
use strict;

use Data::Tabular::Dumper::Writer;

use vars qw( @ISA );
@ISA = qw( Data::Tabular::Dumper::Writer );

###########################################################
sub open
{
    my($package, $param)=@_;

    my($file, $top, $record)=@$param;
    my $self = $package->SUPER::open( $file );

    $top||='DATA';
    $record||='RECORD';

    my $fh = $self->{fh};
    print $fh qq(<?xml version="1.0" encoding="iso-8859-1"?>\n<$top>\n);

    $self->{top} = $top;
    $self->{record} = $record;
    $self->{prefix} = '';

    return $self;
}

###########################################################
sub close
{
    my($self)=@_;
    my $fh = delete $self->{fh};
    return unless $fh;
    print $fh qq(</$self->{top}>\n) ;
}

###########################################################
sub fields
{
    my($self, $fields)=@_;
    $self->{fields}=[@$fields];
}

###########################################################
sub write
{
    my($self, $data)=@_;

    my $fh=$self->{fh};

    my $record = $self->{record};
    my $q = 0;
    if( 1 < @{$self->{fields}} and $self->{fields}[0] eq ''
                               and $data->[0] ne '' ) {
        $record = $data->[0];
        $q++;
    }

    print $fh qq($self->{prefix}  <$record>\n);
    for( ; $q <=$#$data ; $q++ ) {
        my $f = $self->{fields}[$q > $#{$self->{fields}} ? -1 : $q];
        $f = $q if not defined $f or $f eq '';
        my $d=$data->[$q];
        next unless defined $d;
        $d=~s/&/&amp;/g;
        $d=~s/</&lt;/g;
        $d=~s/>/&gt;/g;
        print $fh qq($self->{prefix}    <$f>$d</$f>\n);
    }
    print $fh qq($self->{prefix}  </$record>\n);
}

###########################################################
sub page_start
{
    my( $self, $name ) = @_;
    $self->{prefix} .= '  ';

    $name =~ s/\W/_/g;
    my $fh=$self->{fh};
    print $fh "$self->{prefix}<$name>\n";
}

###########################################################
sub page_end
{
    my( $self, $name ) = @_;
    $name =~ s/\W/_/g;
    my $fh=$self->{fh};
    print $fh "$self->{prefix}</$name>\n";

    substr( $self->{prefix} , -2 ) = '';
}


1;

__END__

=head1 NAME

Data::Tabular::Dumper::XML - XML writer for Data::Tabular::Dumper

=head1 SYNOPSIS

    use Data::Tabular::Dumper;
    use Data::Tabular::Dumper::XML;

    $date=strftime('%Y%m%d', localtime);

    my $dumper = Data::Tabular::Dumper->open(
                            XML => [ "$date.xml", "data" ],
                        );
=head1 DESCRIPTION

Please see the documentation in L<Data::Tabular::Dumper>.

=head1 AUTHOR

Philip Gwyn E<lt>gwyn-at-cpan.orgE<gt>

=head1 SEE ALSO

L<Data::Tabular::Dumper>.

=cut



$Log$
Revision 1.1  2006/03/24 03:53:11  fil
Initial revision


