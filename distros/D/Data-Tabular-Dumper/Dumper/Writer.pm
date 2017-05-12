# $Id: Writer.pm 456 2009-04-15 12:20:59Z fil $
package Data::Tabular::Dumper::Writer;
use strict;

###########################################################
sub open 
{
    my($package, $file )=@_;

    $file = $file->[0] if 'ARRAY' eq ref $file;

    my $fh;
    if( ref $file ) {
        $fh = $file;        # assume it's a valid filehandle
    }
    else {
        $fh=eval { local *FH;};
        open $fh, ">$file" or die "Unable to open $file: $!\n";
    }
    return bless { fh=>$fh, fields=>[] }, $package;
}


###########################################################
sub close
{
    my($self)=@_;
    delete $self->{fh};
}

###########################################################
sub write
{
    my($self, $data)=@_;
    die "You MUST overload ", ref($self), "->write";
}

###########################################################
sub fields 
{
    my( $self, $data ) = @_;
    $self->write( $data );
}

###########################################################
sub page_start
{
    return;
}

###########################################################
sub page_end
{
    return;
}

1;

__END__

=head1 NAME

Data::Tabular::Dumper::Writer - Base class for Data::Tabular::Dumper writers

=head1 SYNOPSIS

    package My::Writer;
    use strict;

    use Data::Tabular::Dumper::Writer;

    use vars qw( @ISA );
    @ISA = qw( Data::Tabular::Dumper::Writer );

    sub open {
        my($package, $param)=@_;

        my( $file, $attr ) = @$param;

        my $self = $package->SUPER::open( $file );

        # Add extra things to $self based on $attr

        return $self;
    }

    # Other methods...

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

