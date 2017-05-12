package Config::JSON;
$Config::JSON::VERSION = '1.5202';
use strict;
use Moo;
use Carp;
use File::Spec;
use JSON 2.0;
use List::Util;

use constant FILE_HEADER    => "# config-file-type: JSON 1\n";

#-------------------------------------------------------------------
has config => (
    is => 'rw',
    default => sub {{}},
);

#-------------------------------------------------------------------
sub getFilePath {
    my $self = shift;
    return $self->pathToFile;
}

#-------------------------------------------------------------------
has pathToFile => (
   is       => 'ro',
   required => 1,
   trigger  => sub {
        my ($self, $pathToFile, $old) = @_;
        if (open(my $FILE, "<", $pathToFile)) {
            # slurp
            local $/ = undef;
            my $json = <$FILE>;
            close($FILE);
            my $conf = eval { JSON->new->relaxed->utf8->decode($json); };
            confess "Couldn't parse JSON in config file '$pathToFile'\n" unless ref $conf;
            $self->config($conf);
		
		    # process includes
		    my @includes = map { glob $_ } @{ $self->get('includes') || [] };
            my @loadedIncludes;
	    	foreach my $include (@includes) {
			    push @loadedIncludes,  __PACKAGE__->new(pathToFile=>$include, isInclude=>1);
	    	}
            $self->includes(\@loadedIncludes);
        } 
        else {
            confess "Cannot read config file: ".$pathToFile;
        }
    },
);

#-------------------------------------------------------------------
has isInclude => (
    is      => 'ro',
    default => sub {0},
);

#-------------------------------------------------------------------
has includes => (
    is => 'rw',
    default => sub {[]},
);

#-------------------------------------------------------------------
sub getIncludes {
    my $self = shift;
    return $self->includes;
}

#-------------------------------------------------------------------
around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    if ( @_ == 1 && ! ref $_[0] ) {
        return $class->$orig(pathToFile => $_[0]);
    }
    else {
        return $class->$orig(@_);
    }
};

#-------------------------------------------------------------------
sub addToArray {
    my ($self, $property, $value) = @_;
    my $array = $self->get($property);
    unless (defined List::Util::first { $value eq $_ } @{$array}) { # check if it already exists
		# add it
      	push(@{$array}, $value);
      	$self->set($property, $array);
	}
}

#-------------------------------------------------------------------
sub addToArrayAfter {
    my ($self, $property, $afterValue, $value) = @_;
    my $array = $self->get($property);
    unless (defined List::Util::first { $value eq $_ } @{ $array }) { # check if it already exists
        my $idx = 0;
        for (; $idx < $#{ $array }; $idx++) {
            if ($array->[$idx] eq $afterValue) {
                last;
            }
        }
        splice @{ $array }, $idx + 1, 0, $value;
        $self->set($property, $array);
    }
}

#-------------------------------------------------------------------
sub addToArrayBefore {
    my ($self, $property, $beforeValue, $value) = @_;
    my $array = $self->get($property);
    unless (defined List::Util::first { $value eq $_ } @{ $array }) { # check if it already exists
        my $idx = $#{ $array };
        for (; $idx > 0; $idx--) {
            if ($array->[$idx] eq $beforeValue) {
                last;
            }
        }
        splice @{ $array }, $idx , 0, $value;
        $self->set($property, $array);
    }
}

#-------------------------------------------------------------------
sub addToHash {
    my ($self, $property, $key, $value) = @_;
    $self->set($property."/".$key, $value);
}

#-------------------------------------------------------------------
sub create {
	my ($class, $filename) = @_;
    if (open(my $FILE,">",$filename)) {
        print $FILE FILE_HEADER."\n{ }\n";
        close($FILE);
    } 
    else {
        warn "Can't write to config file ".$filename;
    }
	return $class->new(pathToFile=>$filename);	
}

#-------------------------------------------------------------------
sub delete {
    my ($self, $param) = @_;
	
	# inform the includes
	foreach my $include (@{$self->includes}) {
		$include->delete($param);
	}
	
	# find the directive
    my $directive   = $self->config;
    my @parts       = $self->splitKeyParts($param);
    my $lastPart    = pop @parts;
    foreach my $part (@parts) {
        $directive = $directive->{$part};
    }
	
	# only delete it if it exists
	if (exists $directive->{$lastPart}) {
		delete $directive->{$lastPart};
		$self->write;
	}
}

#-------------------------------------------------------------------
sub deleteFromArray {
    my ($self, $property, $value) = @_;
    my $array	= $self->get($property);
    for (my $i = 0; $i < scalar(@{$array}); $i++) {
        if ($array->[$i] eq $value) {
            splice(@{$array}, $i, 1);
            last;
        }
    }
    $self->set($property, $array);
}

#-------------------------------------------------------------------
sub deleteFromHash {
    my ($self, $property, $key) = @_;
    $self->delete($property."/".$key);
}

#-------------------------------------------------------------------
sub get {
    my ($self, $property) = @_;

	# they want a specific property
	if (defined $property) {

		# look in this config
		my $value = $self->config;
		foreach my $part ($self->splitKeyParts($property)) {
			$value = eval{$value->{$part}};
            if ($@) {
                confess "Can't access $property. $@";
            }
		}
		return $value if (defined $value);

		# look through includes
		foreach my $include (@{$self->includes}) {
			my $value = $include->get($property);
			return $value if (defined $value);
		}

		# didn't find it
		return undef;
	}
	
	# they want the whole properties list
	my %whole = ();
	foreach my $include (@{$self->includes}) {
		%whole = (%whole, %{$include->get});			
	}
	%whole = (%whole, %{$self->config});
	return \%whole;
}

#-------------------------------------------------------------------
sub getFilename {
    my $self = shift;
    my @path = split "/", $self->pathToFile;
    return pop @path;
}

#-------------------------------------------------------------------
sub set {
    my ($self, $property, $value) 	= @_;

	# see if the directive exists in this config
    my $directive	= $self->config;
    my @parts 		= $self->splitKeyParts($property);
	my $numParts 	= scalar @parts;
	for (my $i=0; $i < $numParts; $i++) {
		my $part = $parts[$i];
		if (exists $directive->{$part}) { # exists so we continue
			if ($i == $numParts - 1) { # we're on the last part
				$directive->{$part} = $value;
				$self->write;
				return 1;
			}
			else {
				$directive = $directive->{$part};
			}
		}
		else { # doesn't exist so we quit
			last;
		}
	}

	# see if any of the includes have this directive
	foreach my $include (@{$self->includes}) {
		my $found = $include->set($property, $value);
		return 1 if ($found);
	}

	# let's create the directive new in this config if it's not an include
	unless ($self->isInclude) {
		$directive	= $self->config;
		my $lastPart = pop @parts;
		foreach my $part (@parts) {
			unless (exists $directive->{$part}) {
				$directive->{$part} = {};
			}
			$directive = $directive->{$part};
		}
	    $directive->{$lastPart} = $value;
		$self->write;
		return 1;
	}

	# didn't find a place to write it	
	return 0;
}

#-------------------------------------------------------------------
sub splitKeyParts {
    my ($self, $key) = @_;
    my @parts = split /(?<!\\)\//, $key;
    map {s{\\\/}{/}} @parts;
    return @parts;
}

#-------------------------------------------------------------------
sub write {
    my $self = shift;
    my $realfile = $self->pathToFile;

    # convert data to json
    my $json = JSON->new->pretty->utf8->canonical->encode($self->config);

    my $to_write = FILE_HEADER . "\n" . $json;
    my $needed_bytes = length $to_write;

    # open as read/write
    open my $fh, '+<:raw', $realfile or confess "Unable to open $realfile for write: $!";
    my $current_bytes = (stat $fh)[7];
    # shrink file if needed
    if ($needed_bytes < $current_bytes) {
        truncate $fh, $needed_bytes;
    }
    # make sure we can expand the file to the needed size before we overwrite it
    elsif ($needed_bytes > $current_bytes) {
        my $padding = q{ } x ($needed_bytes - $current_bytes);
        sysseek $fh, 0, 2;
        if (! syswrite $fh, $padding) {
            sysseek $fh, 0, 0;
            truncate $fh, $current_bytes;
            close $fh;
            confess "Unable to expand $realfile: $!";
        }
        sysseek $fh, 0, 0;
        seek $fh, 0, 0;
    }
    print {$fh} $to_write;
    close $fh;

    return 1;
}


=head1 NAME

Config::JSON - A JSON based config file system.

=head1 VERSION

version 1.5202

=head1 SYNOPSIS

 use Config::JSON;

 my $config = Config::JSON->create($pathToFile);
 my $config = Config::JSON->new($pathToFile);
 my $config = Config::JSON->new(pathToFile=>$pathToFile);

 my $element = $config->get($directive);

 $config->set($directive,$value);

 $config->delete($directive);
 $config->deleteFromHash($directive, $key);
 $config->deleteFromArray($directive, $value);

 $config->addToHash($directive, $key, $value);
 $config->addToArray($directive, $value);

 my $path = $config->pathToFile;
 my $filename = $config->getFilename;

=head2 Example Config File

 # config-file-type: JSON 1
 {
    "dsn" : "DBI:mysql:test",
    "user" : "tester",
    "password" : "xxxxxx",

    # some colors to choose from
    "colors" : [ "red", "green", "blue" ],

    # some statistics
    "stats" : {
            "health" : 32,
            "vitality" : 11
    },

    # including another file
    "includes" : ["macros.conf"]
 }


=head1 DESCRIPTION

This package parses the config files written in JSON. It also does some non-JSON stuff, like allowing for comments in the files. 

If you want to see it in action, it is used as the config file system in WebGUI L<http://www.webgui.org/>.


=head2 Why?

Why build yet another config file system? Well there are a number
of reasons: We used to use other config file parsers, but we kept
running into limitations. We already use JSON in our app, so using
JSON to store config files means using less memory because we already
have the JSON parser in memory. In addition, with JSON we can have
any number of hierarchcal data structures represented in the config
file, whereas most config files will give you only one level of
hierarchy, if any at all. JSON parses faster than XML and YAML.
JSON is easier to read and edit than XML. Many other config file
systems allow you to read a config file, but they don't provide any
mechanism or utilities to write back to it. JSON is taint safe.
JSON is easily parsed by languages other than Perl when we need to
do that.


=head2 Multi-level Directives

You may of course access a directive called "foo", but since the config is basically a hash you can traverse
multiple elements of the hash when specifying a directive name by simply delimiting each level with a slash, like
"foo/bar". For example you may:

 my $vitality = $config->get("stats/vitality");
 $config->set("stats/vitality", 15);

You may do this wherever you specify a directive name.


=head2 Comments

You can put comments in the config file as long as # is the first non-space character on the line. However, if you use this API to write to the config file, your comments will be eliminated.


=head2 Includes

There is a special directive called "includes", which is an array of include files that may be brought in to
the config. Even the files you include can have an "includes" directive, so you can do hierarchical includes.

Any directive in the main file will take precedence over the directives in the includes. Likewise the files
listed first in the "includes" directive will have precedence over the files that come after it. When writing
to the files, the same precedence is followed.

If you're setting a new directive that doesn't currently exist, it will only be written to the main file.

If a directive is deleted, it will be deleted from all files, including the includes.

=head1 INTERFACE

=head2 addToArray ( directive, value )

Adds a value to an array directive in the config file.

=head3 directive

The name of the array.

=head3 value

The value to add.

=head2 addToArrayBefore ( directive, insertBefore, value )

Inserts a value into an array immediately before another item.  If
that item can't be found, inserts at the beginning on the array.

=head3 directive

The name of the array.

=head3 insertBefore

The value to search for and base the positioning on.

=head3 value

The value to insert.


=head2 addToArrayAfter ( directive, insertAfter, value )

Inserts a value into an array immediately after another item.  If
that item can't be found, inserts at the end on the array.

=head3 directive

The name of the array.

=head3 insertAfter

The value to search for and base the positioning on.

=head3 value

The value to insert.



=head2 addToHash ( directive, key, value )

Adds a value to a hash directive in the config file. B<NOTE:> This is really the same as
$config->set("directive/key", $value);

=head3 directive

The name of the hash.

=head3 key

The key to add.

=head3 value

The value to add.


=head2 create ( pathToFile )

Constructor. Creates a new empty config file.

=head3 pathToFile

The path and filename of the file to create.



=head2 delete ( directive ) 

Deletes a key from the config file.

=head3 directive

The name of the directive to delete.


=head2 deleteFromArray ( directive, value )

Deletes a value from an array directive in the config file.

=head3 directive

The name of the array.

=head3 value

The value to delete.



=head2 deleteFromHash ( directive, key )

Delete a key from a hash directive in the config file. B<NOTE:> This is really just the same as doing
$config->delete("directive/key");

=head3 directive

The name of the hash.

=head3 key

The key to delete.



=head2 get ( directive ) 

Returns the value of a particular directive from the config file.

=head3 directive

The name of the directive to return.



=head2 getFilename ( )

Returns the filename for this config.



=head2 pathToFile ( ) 

Returns the filename and path for this config. May also be called as C<getFilePath> for backward campatibility sake.



=head2 includes ( )

Returns an array reference of Config::JSON objects that are files included by this config. May also be called as C<getIncludes> for backward compatibility sake.


=head2 new ( pathToFile )

Constructor. Builds an object around a config file.

=head3 pathToFile

A string representing a path such as "/etc/my-cool-config.conf".



=head2 set ( directive, value ) 

Creates a new or updates an existing directive in the config file.

=head3 directive

A directive name.

=head3 value

The value to set the paraemter to. Can be a scalar, hash reference, or array reference.



=head2 splitKeyParts ( key )

Returns an array of key parts.

=head3 key

A key string. Could be 'foo' (simple key), 'foo/bar' (a multilevel key referring to the bar key as a child of foo), or 'foo\/bar' (a simple key that contains a slash in the key). Don't forget to double escape in your perl code if you have a slash in your key parts like this:

 $config->get('foo\\/bar');

=cut



=head2 write ( )

Writes the file to the filesystem. Normally you'd never need to call this as it's called automatically by the other methods when a change occurs.


=head1 DIAGNOSTICS

=over

=item C<< Couldn't parse JSON in config file >>

This means that the config file does not appear to be formatted properly as a JSON file. Common mistakes are missing commas or trailing commas on the end of a list.

=item C<< Cannot read config file >>

We couldn't read the config file. This usually means that the path specified in the constructor is incorrect.

=item C<< Can't write to config file >>

We couldn't write to the config file. This usually means that the file system is full, or the that the file is write protected.

=back

=head1 PREREQS

L<JSON> L<Moo> L<List::Util> L<Test::More> L<Test::Deep>

=head1 SUPPORT

=over

=item Repository

L<http://github.com/plainblack/Config-JSON>

=item Bug Reports

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Config-JSON>

=back

=head1 AUTHOR

JT Smith  <jt-at-plainblack-dot-com>

=head1 LEGAL

Config::JSON is Copyright 2009 Plain Black Corporation (L<http://www.plainblack.com/>) and is licensed under the same terms as Perl itself.

=cut

1;
