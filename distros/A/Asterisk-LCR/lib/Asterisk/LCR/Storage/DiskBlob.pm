package Asterisk::LCR::Storage::DiskBlob;
use base qw /Asterisk::LCR::Storage/;
use FreezeThaw;
use warnings;
use strict;

use constant DEFAULT_LIMIT => 10000;
our $SORT = undef;
our $SINGLETON = undef;

sub new
{
    my $class = shift;
    $SINGLETON and return $SINGLETON;
    
    my $self  = $class->SUPER::new (@_);
    my $file  = $self->db_file();
    
    $self->{map} = {};
    if (-e $file)
    {
        open FP, "<$file" or die "Cannot read-open $file";
        print STDERR "Loading data, please be patient...";
        while (<FP>)
        {
            chomp();
            my ($key, $data) = split /\:/, $_, 2;
            $self->{map}->{$key} = [ FreezeThaw::thaw ($data) ];
        }
        print STDERR " done.\n";
    }
    
    $SINGLETON = $self;    
    return $self;
}


sub register
{
    my $self   = shift;
    my $prefix = shift;
    
    my %rates  = ();
    for ($self->list ($prefix)) { $rates{$_->provider()} = $_ }
    for (@_)                    { $rates{$_->provider()} = $_ }
    
    $SORT ||= Config::Mini::instantiate ('comparer');    
    my @rates  = sort { $SORT->sortme ($a, $b) } values %rates;
        
    $self->_write_to_memory ($prefix, @rates);
}


sub list
{
    my $self   = shift;
    my $prefix = shift;
    my $limit  = shift || 10000;
    my $res    = $self->{map}->{$prefix};
    return unless $res;
    
    my @res = @{$res};
    return splice @res,0,$limit;
}


sub db_file
{
    my $self = shift;
    return $self->{db_file} || 'lcr.db';
}


sub _write_to_memory
{
    my $self     = shift;
    my $prefix   = shift;
    $self->{map}->{$prefix} = [ @_ ];
}


sub save
{
    my $self = shift;
    my $file = $self->db_file();
    print STDERR "\nWriting $file...\n";
    
    my %map = %{$self->{map}};
    open FP, ">$file" or die "Cannot write-open $file";
    for (keys %map)
    {
        print FP "$_:";
        print FP FreezeThaw::freeze ( @{$map{$_}} );
        print FP "\n";
    }
    close FP;
}


1;


__END__
