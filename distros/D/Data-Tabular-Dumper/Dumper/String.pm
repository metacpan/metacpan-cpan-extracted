# $Id: String.pm 456 2009-04-15 12:20:59Z fil $
package Data::Tabular::Dumper::String;
use strict;

use Text::CSV_XS;

###########################################################
sub open 
{
    my($package, $string_ref)=@_;

    my $self = bless { ref=>$string_ref }, $package;

    $$string_ref = '' unless defined $$string_ref;

    my $csv=Text::CSV_XS->new( { eol=>"\n", binary=>1 } );
    die "No CSV\n" unless $csv;

    $self->{csv} = $csv;

    return $self;
}


###########################################################
sub close
{
    my($self)=@_;
    delete $self->{csv};
}

###########################################################
sub write
{
    my($self, $data)=@_;

    $self->{csv}->combine(@$data);
    ${ $self->{ref} } .= $self->{csv}->string;
    return;
}

*fields = \&write;

###########################################################
sub page_start
{
    my( $self, $name ) = @_;
    ${ $self->{ref} } .= "$name\n";
    return;
}

###########################################################
sub page_end
{
    my( $self, $name ) = @_;
    ${ $self->{ref} } .= "\n";
    return;
}

1;

__END__

=head1 NAME

Data::Tabular::Dumper::String - CSV writer for Data::Tabular::Dumper->dump

=head1 SYNOPSIS

    use Data::Tabular::Dumper;

    Data::Tabular::Dumper->dump( $data );

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

