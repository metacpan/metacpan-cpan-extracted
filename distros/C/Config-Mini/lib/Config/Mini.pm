=head1 NAME

Config::Mini - Very simple INI-style configuration parser


=head1 SAMPLE CONFIGURATION

In your config file:

  # this is a comment
  # these will go in section [general] which is the default
  foo = bar
  baz = buz
  
  [section1]
  key1 = val1
  key2 = val2
  
  [section2]
  key3 = val3
  key4 = arrayvalue
  key4 = arrayvalue2
  key4 = arrayvalue3
  

=head1 USAGE

In your perl code:

use Config::Mini;
my $config = Config::Mini->new ('sample.conf');
print "These are the sections which are defined in the config file:\n";
print join "\n", $config->sections();

# will print 'arrayvalue'
print $config->section ('section2')->{'key4'};
print $config->section ('section2')->{'__key4'}->[2];


=head1 %directives

By default, L<Config::Mini> turns sections into hashes. For instance, the following
section:

  [test]
  foo = bar
  foo = bar2
  baz = buz
  
Will be turned into:

  {
    foo   => 'bar',
    baz   => 'buz',
    __foo => [ 'bar', 'bar2' ],
    __baz => [ 'buz' ],
  }
  
When you write your own objects, having this convention is fine. However, you may want to instantiate
other objects from CPAN than your own. For example, a L<Cache::MemCached> is constructed like this in Perl:

  $memd = Cache::Memcached->new {
    'servers'            => [ "10.0.0.15:11211", "10.0.0.15:11212", "10.0.0.17:11211" ]
    'debug'              => 0,
    'compress_threshold' => 10_000,
  };
  
  
So having the following config won't do:

  [cache]
  %package = Cache::Memcached
  servers  = 10.0.0.15:11211
  servers  = 10.0.0.15:11212
  servers  = 10.0.0.17:11211
  debug    = 0
  compress_threshold = 10_000

Because L<Cache::Memcached> expects 'servers' to be an array, not a scalar.


In this case, you can do the following:

  [cache]
  %package = Cache::Memcached
  @servers = 10.0.0.15:11211
  @servers = 10.0.0.15:11212
  @servers = 10.0.0.17:11211
  debug    = 0
  compress_threshold = 10_000


This will let L<Config::Mini> know that 'servers' is meant to be an array reference.

If you want, you can also let it know that debug and compress_threshold are just scalars
so it doesn't create the '__debug' and '__compress_threshold' attributes, using the dollar
symbol:

  [cache]
  %package = Cache::Memcached
  @servers = 10.0.0.15:11211
  @servers = 10.0.0.15:11212
  @servers = 10.0.0.17:11211
  $debug   = 0
  $compress_threshold = 10_000

The only problem now is that your configuration file is seriously starting to look like Perl,
so I would recommend using these 'tricks' only where it's 100% necessary.


=head1 %include, %package, %constructor

You can use the following commands:

=head2 %include /path/to/file

Will include /path/to/file. Relative paths are supported (it will act as if you were chdir'ed
to the current config file location), but wildcards at not (well, not yet).


=head2 %package My::Package::Name

Will attempt to create an object rather than a file name. For example:

  [database]
  %package = Rose::DB
  %constructor = register_db
  domain   = development
  type     = main
  driver   = mysql
  database = dev_db
  host     = localhost
  username = devuser
  password = mysecret


=head2 %constructor constructor_name

Most Perl objects use new() for their constructor method, however sometimes
the constructor is called something else. If %constructor is specified, then
it will be called instead of new()


=head2 %hashref = true

Some folks prefer to construct their objects this way:

  my $object = Foo->new ( { %args } );
  
Instead of

  my $object = Foo->new ( %args );

This directive allows you to accomodate them (Cache::Cache comes to mind).
So for example, you'd have:

  [cache]
  %package = Cache::FileCache
  %hashref = true
  namespace = MyNamespace
  default_expires_in = 600


=head2 %args = key1 key2 key3

Some modules have constructors where you don't pass a hash, but a simple list of
arguments. For example:

    File::BLOB->from_file( 'filename.txt' );
    
In this case, you can do:

  [fileblob]
  %package = File::Blob
  %constructor = from_file
  %args filename
  filename = filename.txt


=cut
package Config::Mini;
use File::Spec;
use warnings;
use strict;

our $IncludeCount = 0;
our $VERSION = '0.04';
our %CONF = ();
our $OBJS = {};



=head2 my $config = Config::Mini->new ($config_file);

Creates a new L<Config::Mini> object.

=cut
sub new
{
    my $class = shift;
    my $file = shift;
    local %CONF = ();
    local $OBJS = {};
    parse_file ($file);
    
    my $self = bless {}, $class;
    foreach my $key (keys %Config::Mini::CONF)
    {
        $self->{$key} ||= Config::Mini::instantiate ($key);
    }
    
    return $self;
}


=head2 @config_sections = $config->sections();

Returns a list of section names.

=cut
sub sections
{
    my $self = shift;
    return $self->section (@_);
}


=head2 my $hash = $config->section ($section_name);

Returns a hashref (or an object) which represents this config section.

=cut
sub section
{
    my $self = shift;
    my $key  = shift;
    defined $key and return $self->{$key};
    return keys %{$self};
}


=head1 FUNCTIONAL STYLE

If you don't want to use the OO-style, you can use the functions below.


=head2 Config::Mini::parse_file ($filename)

Parses config file $filename

=cut
sub parse_file
{
    my $file = shift;
    local $IncludeCount = 0;
    my @data = read_data ($file);
    parse_data (@data);
}



sub read_data
{
    my $file = shift;
    $IncludeCount > 10 and return;
    $IncludeCount++;
    
    open FP, "$file" or die "Cannot read-open $file";
    my @lines = <FP>;
    close FP;
    
    my @res = ();
    foreach my $line (@lines)
    {
        chomp ($line);
        $line =~ /^\%include\s+/ ? push @res, read_data_include ($file, $line) : push @res, $line;
    }

    $IncludeCount--;    
    return @res;
}


sub read_data_include
{
    my $file = shift;
    my $line = shift;
    $line =~ s/\%include\s+//;
    
    if ($line =~ /^\//)
    {
        $file = $line;
    }
    else
    {
        ($file) = $file =~ /^(.*)\//;
        $file = File::Spec->rel2abs ($file);
        $file .= "/$line";
    }
    
    return read_data ($file);
}


=head2 Config::Mini::parse_data (@data)

Parses @data

=cut
sub parse_data
{
    my @lines = map { split /\n/ } @_;

    my $current = 'general';
    my $count   = 0;
    for (@lines)
    {
        $count++;

        s/\r//g;
        s/\n//g;
        s/^\s+//;
        s/\s+$//;
        $_ || next;

        my $orig = $_;

        s/#.*//;
        s/^\s+//;
        s/\s+$//;
        $_ || next;

        /^\[.+\]/ and do {
            ($current) = $_ =~ /^\[(.+)\]/;
            $CONF{$current} ||= {};
            next;
        };

        /^.+=.+$/ and do {
            my ($key, $value) = split /\s*=\s*/, $_, 2;
            $CONF{$current}->{$key} ||= [];
            push @{$CONF{$current}->{$key}}, $value;
            next;
        };
        
        print STDERR "ConfigParser: Cannot parse >>>$orig<<< (line $count)\n";
    }
}


sub set_config
{
    my $section = shift;
    my $key     = shift;
    $CONF{$section} ||= {};

    if (defined $key) { $CONF{$section}->{$key} = \@_  }
    else              { delete $CONF{$section}->{$key} }
    
    delete $CONF{$section} unless (keys %{$CONF{$section}});
    delete $OBJS->{$section};
}


sub delete_section
{
    my $section = shift;
    delete $CONF{$section};
}


sub write_file
{
    my $filename = shift;
    open FP, ">$filename" or die "Cannot write-open $filename!";
    if ($CONF{general})
    {
        write_file_section ('general', $CONF{'general'});
    }
    for my $key (sort keys %CONF)
    {
        $key eq 'general' and next;
        write_file_section ($key, $CONF{$key});
    }
}


sub write_file_section
{
    my $name = shift;
    my $hash = shift;
    print FP "[$name]\n";
    for my $key (sort keys %{$hash})
    {
        for my $item (@{$hash->{$key}})
        {
            print FP "$key=$item\n";
        }
    }
    print FP "\n";
}


=head2 Config::Mini::get ($context, $key)

Returns the value for $key in $context.

Returns the value as an array if the requested value is an array.

Return the first value otherwise.

=cut
sub get
{
    my $con = shift;
    my $key = shift;
    return wantarray ? @{$CONF{$con}->{$key}} : $CONF{$con}->{$key}->[0]; 
}


=head2 Config::Mini::instantiate ($context)

If $context is used to describe an object, Config::Mini will try to instantiate it.

If $section contains a "package" attribute, Config::Mini will try to load that package and call
a new() method to instantiate the object.

Otherwise, it will simply return a hash reference.

Values can be considered as a scalar or an array. Hence, Config::Mini uses
<attribute_name> for scalar values and '__<attribute_name>' for array values.

=cut
sub instantiate
{
    my $section = shift;
    $CONF{$section} || return;
    
    $OBJS->{$section} ||= do {
        my $config = $CONF{$section};
        my %args   = ();
        foreach my $key (keys %{$config})
        {
            if ($key =~ s/^\@//)
            {
                $args{$key} = $config->{"\@$key"};   
            }
            elsif ($key =~ s/^\$//)
            {
                $args{$key} = $config->{"\$$key"}->[0];                   
            }
            else
            {
                $args{$key}     = $config->{$key}->[0];
                $args{"__$key"} = $config->{$key};
            }
        }

        my $cons   = delete $args{'%constructor'} || 'new';    
        my $class  = delete $args{'%package'} || $args{package} || return \%args;
        my $args   = delete $args{'%args'};
        my $noargs = delete $args{'%noargs'} || 'false';
        
        eval "use $class";
        defined $@ and $@ and warn $@;
        
        my $hashref = delete $args{'%hashref'} || 'false';
        
        my @args = $args ?
            ( map { $args{$_} } split /\s+/, $args ) :
            ( %args );
        
        if    ( lc ($noargs)  eq 'true' ) { $class->$cons()             }
	elsif ( lc ($hashref) eq 'true' ) { $class->$cons ( { @args } ) }
	else { $class->$cons ( @args ) }
    };
    
    return $OBJS->{$section};
}


=head2 Config::Mini::select ($regex)

Selects all section entries matching $regex, and returns a list of instantiated
objects using instantiate() for each of them.

=cut
sub select
{
    my $regex = shift;
    return map  { instantiate ($_) }
           grep /$regex/, keys %CONF;
}


1;


__END__


=head1 AUTHOR

Copyright 2006 - Jean-Michel Hiver
All rights reserved

This module is free software and is distributed under the same license as Perl
itself. Use it at your own risk.
