package Apache::Cache;
#$Id: Cache.pm,v 1.24 2001/09/27 12:56:27 rs Exp $

=pod

=head1 NAME

Apache::Cache - Cache data accessible between Apache childrens

=head1 SYNOPSIS

    use Apache::Cache qw(:status);

    my $cache = new Apache::Cache(default_expires_in=>"5 minutes");

    # if the if the next line is called within 10 minutes, then this 
    # will return the cache value overwise, this will return undef and the
    # status method will be equal to the constant EXPIRED (exported by Apache::Cache
    # on demande via the :status tag)

    # the next line try to get the data from the cache, if the data is stored in
    # in the cache and if it not expired, then this return the data. Otherwise
    # if data have never been store in the cache, or if it's expired, this will
    # return undef and the status() method will be equal to constant EXPIRED (exported
    # by Apache::Cache on demand, via the :status tag)

    my $value = $cache->get('Key');

    if($cache->status eq EXPIRED)
    {
        # can't get the data from the cache, we will need to get it by the normal way
        # (via database, from file...)
        $value = get_my_data('Key'); # here, the get_my_data() function is a function of your
                                     # programe that generate a fresh value

        # this data have to expires in 30 secondes
        my $expires_in = '30 secondes';
        $cache->set(Key => $value, $expires_in);
    }
    elsif($cache->status eq FAILURE)
    {
        # don't use cache, cache maybe busy by another child or something goes wrong
        $value = get_my_data('Key');
    }

=head1 DESCRIPTION

This module allows you to cache data easily through shared memory. Whithin the framework 
of an apache/mod_perl use, this cache is accessible from any child process. The data 
validity is managed in the Cache::Cache model, but as well based on time than on size 
or number of keys.

Additionnally, you can implement a cache with Apache::Cache in your module without the risk
of namespace clash because Apache::Cache is enclosed in the constructor's package's caller 
(see L<Apache::SharedMem> for more details).

=head1 USAGE

For mod_perl users:

in your httpd.conf, put this directive:

    PerlAddVar PROJECT_DOCUMENT_ROOT /path/to/your/project/root/

and in your startup.pl:

    use Apache::Cache ();

See L<Apache::SharedMem> for more details.

=cut

BEGIN
{
    use strict;
    use 5.005;
    use Carp;
    use Apache::SharedMem qw(:all);
    use Time::ParseDate;

    use base qw(Apache::SharedMem Exporter);

    %Apache::Cache::EXPORT_TAGS = 
    (
        all       => [qw(EXPIRED SUCCESS FAILURE EXPIRES_NOW EXPIRES_NEVER LOCK_EX LOCK_SH LOCK_UN LOCK_NB)],
        expires   => [qw(EXPIRES_NOW EXPIRES_NEVER)],
        status    => [qw(SUCCESS FAILURE EXPIRED)],
        lock      => [qw(LOCK_EX LOCK_SH LOCK_UN LOCK_NB)],
    );
    @Apache::Cache::EXPORT_OK   = @{$Apache::Cache::EXPORT_TAGS{'all'}};

    # SUCCESS => 1
    # FAILURE => 2
    use constant EXPIRED        => 4;

    use constant EXPIRES_NOW    => 1;
    use constant EXPIRES_NEVER  => 0;

    $Apache::Cache::VERSION     = '0.05';
}

=pod

=head1 METHODS

=head2 new  (cachename=> 'cachename', default_expires_in=> '1 second', max_keys=> 50, max_size=> 1_000)

Constuct a new Apache::Cache's instance.

=over 4

=item *

C<default_expires_in> optional, date

The default data expiration time for objects place in the cache. Integers is interpreted in seconds, constant
EXPIRES_NOW make data expire imédiately and constant EXPIRES_NEVER make the data never expire. The
timeout can also be in a human readable format, see L<Time::ParseDate> for this format specification.

Defaults to constant EXPIRES_NEVER if not explicitly set. 

=item *

C<max_keys> optional, integer

If you set more than C<max_keys> keys, olders are automatically removed. Usefull to control the cache's grow.
NOTE: if you know the exact length of your keys, use this option to control the cache size instead of the
C<max_size> option.

Defaults to no max_keys

=item *

C<max_size> optional, integer

no yet implemented

=item *

C<cachename> optional, string

The namespace associated with this cache. 

Defaults to "Default" if not explicitly set. 

=item *

C<default_lock_timeout> optional, integer

Number of second(s) to wait for locks used each time manipulating data in the shared memory.

Defaults to not waiting. This means a get() - for expample - on a temporary locked
key - certainely by another process - will return a FAILED status.

=back

Additionnaly, all Apache::SharedMem parameters are also customizable. See L<Apache::SharedMem>.

=cut

sub new
{
    my $pkg     = shift;
    my $class   = ref($pkg) || $pkg;

    my $options = 
    {
        namespace           => (caller())[0],
        cachename           => 'Default',
        default_expires_in  => EXPIRES_NEVER,
        max_keys            => undef(),
        max_size            => undef(),
        default_lock_timeout=> undef(),
    };

    croak("odd number of arguments for object construction")
      if(@_ % 2);
    my @del;
    for(my $x = 0; $x < $#_; $x += 2)
    {
        if(exists($options->{lc($_[$x])}))
        {
            $options->{lc($_[$x])} = $_[($x + 1)];
            # We split off this parameter from the main argument list.
            # Remaining arguments will be send to Apache::SharedMem
            splice(@_, $x, 2);
            $x -= 2;
        }
    }

    foreach my $name (qw(cachename namespace))
    { 
        croak("$pkg object creation missing $name parameter.")
          unless(defined($options->{$name}) && $options->{$name} ne '');
    }

    my $self = $class->SUPER::new(@_, namespace=>$options->{namespace});
    return(undef()) unless(defined($self));
    $self->{cache_options} = $options;

    unless($self->SUPER::exists($options->{cachename}, $self->_lock_timeout))
    {
        return(undef()) if($self->SUPER::status eq FAILURE);
        $self->_init_cache || return undef;
    }

    bless($self, $class);
    return($self);
}

=pod

=head2 set (identifier => data, [timeout])

    $cache->set(mykey=>'the data to cache', '15 minutes');
    if($cache->status & FAILURE)
    {
        warn("can't save data to cache: $cache->error");
    }

Store an item in the cache.

=over 4

=item *

C<identifier> required, string

A string uniquely identifying the data. 

=item *

C<data> required, scalar or reference to any perl data type, except CODE and GLOB 

The data to store in the cache.

=item *

C<timeout> optional, date

The data expiration time for objects place in the cache. Integers is interpreted in seconds, constant
EXPIRES_NOW make data expire imédiately and constant EXPIRES_NEVER make the data never expire. The
timeout can also be in a human readable format, see L<Time::ParseDate> for this format specification.

=back

On failure this method return C<undef()> and set status to FAILURE, see status() method below

status : FAILURE SUCCESS

=cut

sub set
{
    my $self         = shift;
    my $key          = defined($_[0]) && $_[0] ne '' ? shift : croak(defined($_[0]) ? 'Not enough arguments for set method' : 'Invalid argument "" for set method');
    my $value        = defined($_[0]) ? shift : croak('Not enough arguments for set method');
    my $time         = defined($_[0]) ? shift : $self->{cache_options}->{default_expires_in};
    my $lock_timeout = $self->{cache_options}->{default_lock_timeout};
    croak('Too many arguments for set method') if(@_);
    $self->_unset_error;
    $self->_debug;

    if($key eq '_cache_metadata')
    {
        $self->_set_status(FAILURE);
        $self->_set_error("$key: reserved key");
        return(undef());
    }

    my $timeout;
    if($time)
    {
        if($time =~ m/\D/)
        {
            $timeout = parsedate($time, TIMEFIRST=>1, PREFER_FUTURE=>1);
            unless(defined $timeout)
            {
                $self->_set_error("error on timeout string decoding. time string requested: $time");
                $self->_set_status(FAILURE);
                return(undef());
            }
        }
        elsif($time eq EXPIRES_NOW)
        {
            $timeout = EXPIRES_NOW;
        }
        else
        {
            $timeout = time() + $time;
        }
    }
    else
    {
        $timeout = EXPIRES_NEVER;
    }

    $self->_debug('timeout is set for expires in ', ($timeout - time()), ' seconds');

    if(defined $lock_timeout ? $self->lock(LOCK_EX, $lock_timeout) : $self->lock(LOCK_EX|LOCK_NB))
    {
        my $data = $self->_get_datas || return(undef());
        $data->{$key} = $value;
        $data->{'_cache_metadata'}->{'timestamps'}->{$key} = $timeout;
        push(@{$data->{'_cache_metadata'}->{'queue'}}, $key);

        $self->_check_keys($data);
        $self->_check_size($data);

        $self->SUPER::set($self->{cache_options}->{cachename}=>$data, NOWAIT);
        my $rv = $self->status; # saving returned status
        $self->unlock; # don't wait for Apache::SharedMem to auto unlock on destroy
        return(undef()) if($rv eq FAILURE);

        return($value);
    }
    else
    {
        $self->_set_error('can\'t get exclusive lock for "set" method');
        $self->_set_status(FAILURE);
        return(undef());
    }
}

=pod

=head2 get (identifier)

    my $value = $cache->get('Key');

    if($cache->status & (EXPIRED | FAILURE)) # if status is EXPIRED or FAILURE
    {
        $value = 'fresh value';
    }

Fetch the data specified. If data where never set, or if data have expired, this method return
C<undef> and status is set to EXPIRED.

=over 4

=item *

C<identifier> required, string

A string uniquely identifying the data. 

=back

status : FAILURE SUCCESS EXPIRED

=cut

sub get
{
    if(@_ != 2)
    {
        confess('Apache::Cache: Too many arguments for "get" method') if(@_ > 2);
        confess('Apache::Cache: Not enough arguments for "get" method') if(@_ < 2);
    }
    my($self, $key) = @_;
    
    my $data    = $self->_get_datas || return(undef());
    unless(exists $data->{$key})
    {
        $self->_set_status(EXPIRED);
        return(undef());
    }
    my $value   = $data->{$key};
    my $timeout = $data->{_cache_metadata}->{timestamps}->{$key};

    if(!defined $timeout || $timeout == EXPIRES_NOW || ($timeout != EXPIRES_NEVER && $timeout <= time()))
    {
        $self->_set_error("data was expired");
        $self->delete($key); # if delete failed, error string will be its own but not status
        $self->_set_status(EXPIRED);
        return(undef());
    }
    else
    {
        $self->_set_status(SUCCESS);
        return($value);
    }
}

=pod

=head2 delete (identifier)

Delete the data associated with the identifier from the cache.

=over 4

=item *

C<identifier> required, string

A string uniquely identifying the data. 

=back

status: SUCCESS FAILURE

=cut

sub delete
{
    if(@_ != 2)
    {
        confess('Apache::Cache: Too many arguments for "delete" method') if(@_ > 2);
        confess('Apache::Cache: Not enough arguments for "delete" method') if(@_ < 2);
    }
    my($self, $key)  = @_;
    my $lock_timeout = $self->{cache_options}->{default_lock_timeout};

    my $rv = undef;
    if(defined $lock_timeout ? $self->lock(LOCK_EX, $lock_timeout) : $self->lock(LOCK_EX|LOCK_NB))
    {
        my $data = $self->_get_datas || return(undef());
        if(exists $data->{$key})
        {
            $rv = delete($data->{$key});
            delete($data->{_cache_metadata}->{timestamps}->{$key});
            $data->{_cache_metadata}->{queue} = \@{grep($_ ne $key, @{$data->{_cache_metadata}->{queue}})};
            $self->SUPER::set($self->{cache_options}->{cachename}=>$data);
            return(undef()) if($self->status & FAILURE);
        }
        $self->unlock;
    }
    return($rv);
}

=head2 clear

Remove all objects from the namespace associated with this cache instance.

status: SUCCESS FAILURE

=cut

sub clear
{
    my $self = shift;
    $self->_init_cache;
}

# inherited from Apache::SharedMem

=head2 status

Return the last called method status. This status should be used with bitmask operators
&, ^, ~ and | like this :

    # is last method failed ?
    if($object->status & FAILURE) {something to do on failure}

    # is last method don't succed ?
    if($object->status ^ SUCCESS) {something to do on failure}

    # is last method failed or expired ?
    if($object->status & (FAILURE | EXPIRED)) {something to do on expired or failure}

It's not recommended to use equality operator (== and !=) or (eq and ne), they may don't
work in future versions.

To import status' constants, you have to use the :status import tag, like below :

    use Apache::Cache qw(:status);

=cut
    

sub _check_keys
{
    my($self, $data) = @_;

    my $max_keys = $self->{cache_options}->{max_keys};
    return() unless(defined $max_keys && $max_keys);
    my $metadata = $data->{_cache_metadata};
    my $nkeys    = @{$metadata->{queue}};
    $self->_debug("cache have now $nkeys keys");
    if($nkeys > $max_keys)
    {
        my $time = time();
        my $nkeys_target = int($max_keys - ($max_keys/10));
        $self->_debug("cache is full, max_key: $max_keys, current key counts: $nkeys, cleaning ", $nkeys - $nkeys_target, " keys");
        # cheching for expired datas
        for(my $i = $nkeys - 1; $i >= 0; $i--)
        {
            if($metadata->{timestamps}->{$metadata->{queue}->[$i]} > $time)
            {
                my $key = $metadata->{queue}->[$i];
                $self->_debug("$key is out of date, discarding");
                delete($data->{$key});
                delete($metadata->{timestamps}->{$key});
                @{$metadata->{queue}} = grep($_ ne $key, @{$metadata->{queue}});
                last if(--$nkeys <= $nkeys_target);
            }
        }
        if($nkeys > $nkeys_target)
        {
            # splice of delete candidates
            my @key2del = splice(@{$metadata->{queue}}, 0, ($nkeys - $nkeys_target - 1));
            $self->_debug('cleaning not timed out keys: ', join(', ', @key2del));
            delete(@$data{@key2del});
            delete(@{$metadata->{timestamps}}{@key2del});
        }
    }
}

sub _check_size
{
    my($self, $data) = @_;

    my $max_size = $self->{cache_options}->{max_keys};
    return() unless(defined $max_size && $max_size);
}

sub _init_cache
{
    my $self = shift;
    my $cache_registry =
    {
        _cache_metadata => 
        {
            timestamps  => {},
            queue       => [],
        }
    };
    $self->SUPER::set($self->{cache_options}->{cachename}=>$cache_registry, $self->_lock_timeout);

    return($self->SUPER::status eq FAILURE ? undef : 1);
}

sub _lock_timeout
{
    my $self         = shift;
    my $lock_timeout = $self->{cache_options}->{default_lock_timeout};
    return(defined $lock_timeout ? $lock_timeout : NOWAIT);
}

sub _get_datas
{
    my $self = shift;
    
    my $data = $self->SUPER::get($self->{cache_options}->{cachename}, $self->_lock_timeout);
    if($self->status eq FAILURE)
    {
        $self->_set_error("can't get the cacheroot: ", $self->error);
        return(undef());
    }

    croak("Apache::Cache: wrong data format.")
      if(ref($data) ne 'HASH' || ! exists $data->{_cache_metadata});
    
    return($data);
}

1;

=pod

=head1 EXPORTS

=head2 Default exports

None.

=head2 Available exports

Following constant is available for exports : EXPIRED SUCCESS FAILURE 
EXPIRES_NOW EXPIRES_NEVER LOCK_EX LOCK_SH LOCK_UN.

=head2 Export tags defined

The tag ":all" will get all of the above exports.
Following tags are also available :

=over 4

=item

:status

Contents: SUCCESS FAILURE EXPIRED

This tag is really recommended to the importation all the time.

=item

:expires

Contents: EXPIRES_NOW EXPIRES_NEVER

=item

:lock

Contents: LOCK_EX LOCK_SH LOCK_UN LOCK_NB

=back

=head1 KNOW BUGS

Under mod_perl, with eavy load, this error may occured some time:

    Apache::SharedMem object initialization: Unable to initialize root ipc shared memory
    segment: File exists at /usr/local/lib/perl5/site_perl/5.005/Apache/SharedMem.pm line 929

We not really understand the probleme source, so any help will be appreciated. For fixing
this problem when it occured, you should stop apache, clean the ipc segment and restart
apache.

=head1 AUTHOR

Olivier Poitrey E<lt>rs@rhapsodyk.netE<gt>

=head1 LICENCE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with the program; if not, write to the Free Software
Foundation, Inc. :

59 Temple Place, Suite 330, Boston, MA 02111-1307

=head1 COPYRIGHT

Copyright (C) 2001 - Olivier Poitrey

=head1 PREREQUISITES

Apache::Cache needs Apache::SharedMem available from the CPAN.

=head1 SEE ALSO

L<Apache::SharedMem>

=head1 HISTORY

$Log: Cache.pm,v $
Revision 1.24  2001/09/27 12:56:27  rs
documentation upgrade

Revision 1.23  2001/09/24 08:18:20  rs
status now return bitmask values

Revision 1.22  2001/09/21 16:24:13  rs
new method clear
new private methods _init_cache and _lock_timeout
new constructor parameter 'default_lock_timeout'

Revision 1.21  2001/09/21 12:42:53  rs
adding pod section KNOW BUGS

Revision 1.20  2001/09/20 12:40:18  rs
Documentation update: add an EXPORTS section

Revision 1.19  2001/09/19 16:22:38  rs
fixe a pod bug

Revision 1.18  2001/09/19 15:34:17  rs
major doc update (METHOD section)

Revision 1.17  2001/09/19 13:37:43  rs
0.04 => 0.05

Revision 1.16  2001/09/19 13:37:09  rs
- constructor have now a default value for "cachename", and the 'cachename'
parameter is now optional

- Documentation upgrade (SINOPSYS simplified)

Revision 1.15  2001/08/29 07:45:32  rs
add mod_perl specifique documentation

Revision 1.14  2001/08/28 13:22:46  rs
major bugfix: _check_keys method wasn't clean keys correctly

Revision 1.13  2001/08/28 08:42:38  rs
set method wasn't unlock on exit !

Revision 1.12  2001/08/17 13:26:36  rs
some minor pod modifications

Revision 1.11  2001/08/17 13:20:45  rs
- fix major bug in "get" method: on first timeout, status was set to
  "delete" method's status (often SUCCESS) instead of EXPIRED
- add some sections to pod documentation

