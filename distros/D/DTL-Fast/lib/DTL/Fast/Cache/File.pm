package DTL::Fast::Cache::File;
use strict; use warnings FATAL => 'all'; 
use parent 'DTL::Fast::Cache::Compressed';

#@Override
sub new
{
    my( $proto, $dir, %kwargs ) = @_;

    die "You should pass a cache directory to the constructor of ".__PACKAGE__
        if not $dir;
        
    $dir =~ s{[\/]+$}{}gs;
    
    if( 
        -d $dir
        and -w $dir
    )
    {
        $kwargs{'dir'} = $dir;
    }
    else
    {
        die "$dir is not a directory or it's not writable for me";
    }
    
    return $proto->SUPER::new(%kwargs);
}

#@Override
sub read_compressed_data
{
    my( $self, $key ) = @_;
    my $result; 
    
    my $filename = sprintf '%s/%s.dtc', $self->{'dir'}, $key;
    
    if( -e $filename )
    {
        if( open my $IF, '<', $filename )
        {
            binmode $IF;
            local $/ = undef;
            $result = <$IF>;
            close $IF;
        }
        else
        {
            die "Error opening cache file $filename for reading: $!";
        }
    }
    
    return $result;    
}

#@Override
sub write_compressed_data
{
    my( $self, $key, $data ) = @_;
    my $filename = sprintf '%s/%s.dtc', $self->{'dir'}, $key;
    
    if( open my $OF, '>', $filename )
    {
        binmode $OF;
        print $OF $data;
        close $OF;
    }
    else
    {
        die "Error opening cache file $filename for writing: $!";
    }
    return $self
}


1;