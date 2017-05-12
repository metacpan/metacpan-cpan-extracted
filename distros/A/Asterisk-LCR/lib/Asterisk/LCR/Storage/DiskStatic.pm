package Asterisk::LCR::Storage::DiskStatic;
use base qw /Asterisk::LCR::Storage/;
use FreezeThaw;
use warnings;
use strict;

use constant DEFAULT_LIMIT => 10000;
our $SORT = undef;


sub register
{
    my $self   = shift;
    my $prefix = shift;
    my %rates  = ();
    for ($self->list ($prefix)) { $rates{$_->provider()} = $_ }
    for (@_)                    { $rates{$_->provider()} = $_ }

    $SORT ||= Config::Mini::instantiate ('comparer');    
    my @rates  = sort { $SORT->sortme ($a, $b) } values %rates;
    
    $self->_write_to_disk ($prefix, @rates);
}


sub list
{
    my $self = shift;
    my $prefix = shift;
    return $self->_read_from_disk ($prefix);
}


sub base_dir
{
    my $self = shift;
    return $self->{base_dir} || 'lcr_db';
}


sub _write_to_disk
{
    my $self     = shift;
    my $base_dir = $self->base_dir();
    my $prefix   = shift;
    my $dir      = join '/', split //, $prefix;
    $dir         = "$base_dir/$dir";

    _mkdir_p ($dir);

    open FP, ">$dir/index.obj" || die "Cannot write-open $dir/index.obj";
    print FP FreezeThaw::freeze (@_);
    close FP;
}


sub _read_from_disk
{
    my $self     = shift;
    my $prefix   = shift;
    my $limit    = shift || DEFAULT_LIMIT;
    my $base_dir = $self->base_dir();
    
    my $found = 0;
    my @res   = ();
    
    while ($prefix ne '')
    {
        my $dir = join '/', split //, $prefix;
        $dir    = "$base_dir/$dir";
        -e "$dir/index.obj" and do {
            open FP, "<$dir/index.obj" or die "Cannot read-open $dir/index.obj";
            my $data = join '', <FP>;
            close FP;
            
            my @res = FreezeThaw::thaw ($data);
            return splice @res, 0, $limit;
        };

        chop ($prefix);
    }
    
    return ();
}


sub _mkdir_p
{
    my $dir = shift || return;
    return if (-d $dir);

    my ($parent, $name) = $dir =~ /(.*)\/(.*)/;
    _mkdir_p ($parent);

    mkdir ($dir);
}


sub save
{
}


1;


__END__
