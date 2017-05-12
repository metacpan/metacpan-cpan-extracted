package Asterisk::LCR::Locale;
use base qw /Asterisk::LCR::Object/;
use warnings;
use strict;


sub new
{
    my $class = shift;
    my $self  = $class->SUPER::new (id => @_) || return;
    $self->parse();
    return $self;
}


# does global => local => global ($prefix) conversion
sub normalize
{
    my $self = shift;
    my $prefix = shift;
    return $self->local_to_global ($self->global_to_local ($prefix));
}


sub global_to_local
{
    my $self = shift;
    my $num  = shift;
    
    $self->{global_to_local_cache}->{$num} ||= do {
        my $map  = $self->{global_to_local};
	
        foreach my $prefix ( sort { length ($b) <=> length ($a) } keys %{$map} )
        {
            my $val  = $map->{$prefix};
            $num =~ s/^_$prefix/_$val/          and return ($prefix =~ /^\d*$/) ? $num : $self->global_to_local ($num);
            $num =~ s/^$prefix/$map->{$prefix}/ and return ($prefix =~ /^\d*$/) ? $num : $self->global_to_local ($num);
        }
	
	$num;
    };
    
    return $self->{global_to_local_cache}->{$num};
}


sub local_to_global
{
    my $self = shift;
    my $num  = shift;
    
    $self->{local_to_global_cache}->{$num} ||= do {
	my $map  = $self->{local_to_global};

        foreach my $prefix ( sort { length ($b) <=> length ($a) } keys %{$map} )
        {
            my $val  = $map->{$prefix};
            $num =~ s/^_$prefix/_$val/          and return ($prefix =~ /^\d*$/) ? $num : $self->local_to_global ($num);
            $num =~ s/^$prefix/$map->{$prefix}/ and return ($prefix =~ /^\d*$/) ? $num : $self->local_to_global ($num);
        }

        $num;
    };
    
    return $self->{local_to_global_cache}->{$num};
}


sub validate
{
    my $self = shift;
    my $id = $self->id() or do {
        die "asterisk/lcr/locale/id/undefined";
    	return 0;
    };
    
    $self->path() or do {
        die "asterisk/lcr/locale/id/no_path : $id";
    	return 0;
    };
    
    return 1;
}


sub id
{
    my $self = shift;
    return $self->{id};
}


sub set_id
{
    my $self = shift;
    $self->{id} = shift;
}


sub parse
{
    my $self = shift;
    my @data = $self->get_lines();
 
    $self->{global_to_local} = {};
    $self->{local_to_global} = {};
 
    foreach my $line (@data)
    {
        my ($local, $global) = $self->parse_line ($line);
        defined $local and defined $global or next;
        $self->{global_to_local}->{$global} = $local   if ($local   =~ /^\d*$/);
        $self->{local_to_global}->{$local}  = $global  if ($global  =~ /^\d*$/);
    }
}


sub parse_line
{
    my $self = shift;
    my $line = shift || return;
    $line =~ /^\s*\#/ and return;

    my ($one, $two) = $line =~ /\"(.*?)\".*\"(.*?)\"/;
    return () unless (defined $one and defined $two);
    
    return ($one, $two);
}


sub get_lines
{
    my $self = shift;
    my $id   = $self->id();
    my $file = $self->path() || return ();
    
    open FP, "<$file" || die "Cannot read-open $file";
    my @res  = map { s/\r//g; s/\n//g; $_ } <FP>;
    close FP;
    
    return @res;
}


sub path 
{
    my $self = shift;

    my $path = $self->id();
    $path    = "Asterisk/LCR/Locale/" . $path . ".txt" unless ($path =~ /\/.*\.txt$/);

    for ('.', @INC)
    {
        -e "$_/$path" and return "$_/$path";
    }
    return;
}


1;


__END__
