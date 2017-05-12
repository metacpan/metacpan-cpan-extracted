# $Id: Excel.pm 456 2009-04-15 12:20:59Z fil $
package Data::Tabular::Dumper::Excel;
use strict;

use Spreadsheet::WriteExcel;

###########################################################
sub open 
{
    my($package, $param)=@_;
    my($file)=@$param;
    my $book=Spreadsheet::WriteExcel->new($file);

    my $header=$book->addformat();
    $header->set_bold();
    my $default=$book->addformat();

    return bless {book=>$book, row=>0, header=>$header, 
                  empty=>1,
                  default=>$default}, $package;
}

###########################################################
sub close
{
    my($self)=@_;
    delete $self->{sheet};
    delete $self->{header};
    if( $self->{book} ) {
        $self->{book}->close();
        delete $self->{book};
    }
}


###########################################################
sub page_start
{
    my( $self, $name ) = @_;

    $self->{row} = 0;
    $self->{sheet} = $self->{book}->add_worksheet( $name );

    return;
}

###########################################################
sub page_end
{
    my( $self, $name ) = @_;

    delete $self->{sheet};
    $self->{row} = 0;
    return;
}


###########################################################
sub __write
{
    my($self, $data, $format)=@_;

    $self->{sheet} ||= $self->{book}->add_worksheet();

    my $row=$self->{row}++;
    my $col=0;
    foreach my $d (@$data) {
        $self->{sheet}->write($row, $col, $d, $format);
        $col++;
    }
}

###########################################################
sub fields
{
    my($self, $fields)=@_;
    $self->__write($fields, $self->{header});
}


###########################################################
sub write
{
    my($self, $data)=@_;
    $self->__write($data, $self->{default});
}

1;

__END__

=head1 NAME

Data::Tabular::Dumper::Excel - Excel writer for Data::Tabular::Dumper

=head1 SYNOPSIS

    use Data::Tabular::Dumper;
    use Data::Tabular::Dumper::Excel;

    $date=strftime('%Y%m%d', localtime);

    my $dumper = Data::Tabular::Dumper->open(
                            Excel => [ "$date.xls" ],
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

