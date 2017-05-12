# $Id: CSV.pm 456 2009-04-15 12:20:59Z fil $
package Data::Tabular::Dumper::CSV;
use strict;
use Text::CSV_XS;

use Data::Tabular::Dumper::Writer;

use vars qw( @ISA );
@ISA = qw( Data::Tabular::Dumper::Writer );

###########################################################
sub open 
{
    my($package, $param)=@_;

    my( $file, $attr ) = @$param;

    my $self = $package->SUPER::open( $file );

    my $csv=Text::CSV_XS->new( $attr );
    die "No CSV\n" unless $csv;

    my $fh = $self->{fh};
    $self->{csv} = $csv;

    return $self;
}


###########################################################
sub close
{
    my($self)=@_;

    $self->SUPER::close();
    delete $self->{csv};
}

###########################################################
sub write
{
    my($self, $data)=@_;
    my $fh=$self->{fh};
    $self->{csv}->combine(@$data);
    print $fh $self->{csv}->string;
}

###########################################################
sub page_start
{
    my( $self, $name ) = @_;
    my $fh=$self->{fh};
    print $fh "$name\n";
}

###########################################################
sub page_end
{
    my( $self, $name ) = @_;
    my $fh=$self->{fh};
    print $fh "\n";
}

1;

__END__

=head1 NAME

Data::Tabular::Dumper::CSV - CSV writer for Data::Tabular::Dumper

=head1 SYNOPSIS

    use Data::Tabular::Dumper;
    use Data::Tabular::Dumper::XML;

    $date=strftime('%Y%m%d', localtime);

    my $dumper = Data::Tabular::Dumper->open(
                            CSV => [ "$date.csv", { eol=>"\n" } ],
                        );
=head1 DESCRIPTION

Please see the documentation in L<Data::Tabular::Dumper>.

=head1 AUTHOR

Philip Gwyn E<lt>gwyn-at-cpan.orgE<gt>

=head1 SEE ALSO

L<Data::Tabular::Dumper>.

=cut


$Log$
Revision 1.1  2006/03/24 03:53:10  fil
Initial revision

