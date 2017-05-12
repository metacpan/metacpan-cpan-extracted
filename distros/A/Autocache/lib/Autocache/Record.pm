package Autocache::Record;

use strict;
use warnings;

use Autocache::Logger qw(get_logger);

our $AUTOLOAD;

sub new
{
    my ($class,%args) = @_;
    my $now = time;
    $args{name} = 'unknown'
        unless defined $args{name};
    $args{create_time} = $now
        unless defined $args{create_time};
    my $self = { %args };
    return bless $self, $class;
}

sub name
{
    $_[0]->{name};
}

sub create_time
{
    $_[0]->{create_time};
}

sub age
{
    time - $_[0]->create_time;
}

sub to_string
{
    my ($self) = @_;
    return sprintf 'name: %s - key: %s - create_time: %d - age: %d',
        $self->name,
        $self->key,
        $self->create_time,
        $self->age;
}

sub AUTOLOAD
{
    my ($self) = @_;
    return if $AUTOLOAD =~ /::DESTROY$/;
    get_logger()->debug( "AUTOLOAD $AUTOLOAD" );
    if( $AUTOLOAD =~ m/^.*::(\w+?)$/ )
    {
        my $name = $1;
        {
            no strict 'refs';
            *{$AUTOLOAD} = sub
            {
                if( scalar @_ > 1 )
                {
                    $_[0]->{$name} = $_[1];
                }
                else
                {
                    return $_[0]->{$name};
                }
            };
        }
        goto &{$AUTOLOAD};
    }
    get_logger()->error( "AUTOLOAD failed : $AUTOLOAD" );
}

1;
