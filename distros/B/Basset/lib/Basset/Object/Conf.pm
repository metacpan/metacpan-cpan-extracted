package Basset::Object::Conf;

#Basset::Object::Conf Copyright and (c) 2002, 2003, 2004, 2005, 2006 James A Thomason III
#Basset::Object::Conf is distributed under the terms of the Perl Artistic License.

=pod

=head1 NAME

Basset::Object::Conf - used to read conf files

=head1 AUTHOR

Jim Thomason, jim@jimandkoka.com

=head1 DESCRIPTION

It's good not to set up default values inside of your module. Believe me, I know. Lord knows I've gotten chewed out enough for Carp::Notify
having the defaults in the module. Anyway, this module includes instructions for the conf file format, how the read_conf_file method works,
and some bits of interaction with the rest of the system. See Basset::Object for more information.

=cut


$VERSION = '1.03';

#
# Basset::Object::Conf isa Basset::Object, but there are circular inheritance reasons. So, instead,
# @ISA is set from within the read_conf_file method
#
#
#use Basset::Object;
#@ISA = qw(Basset::Object);

use strict;
use warnings;

=pod

=head1 SET-UP

You'll need to specify your conf files. There is the @conf_files array, toss in as many conf files as you'd like

 my @conf_files = qw(
 	/etc/mail.bulkmail.cfg
 	/etc/mail.bulkmail.cf2
 );
 
It'll just silently ignore any conf files that aren't present, so don't expect any errors. That's to allow you
to place multiple conf files in for use on multiple servers and then not worry about them.

Multiple conf files are in significance order. So if mail.bulkmail.cfg and mail.bulkmail.cf2 both define a value
for 'foo', then the one in mail.bulkmail.cfg is used. And so on, conf files listed earlier are more important.
There is no way for a program to later look at a less significant conf value.

=cut

our @conf_files = (qw(
		/etc/basset.conf
		./basset.conf
		Basset/Object/basset.conf
		lib/Basset/Object/basset.conf
	), 
);
our %conf_files = ();

sub conf_files {
	my $class = shift;
	foreach (reverse @_) {
		unshift @conf_files, $_ unless $conf_files{$_}++;
	}

	return @conf_files;
		
}

our $default_package = 'Basset::Object';

=pod

=over

=item read_conf_file

read_conf_file will read in the conf files specified in the @conf_files array up at the top.

You can also pass in a list of conf files to read, in most to least significant order, same as the @conf_files array.

 my $conf = Mail::Bulkmail::Object->read_conf_file();
 or
 my $conf = Mail::Bulkmail::Object->read_conf_file('conf_files' => '/other/conf.file');
 or
 my $conf = Mail::Bulkmail::Object->read_conf_file('conf_files' => ['/other/conf.file', '/additional/conf.file']);
 
If you pass in a list of conf files, then the internal @conf_files array is bypassed.

$conf is a hashref of hashrefs. the main keys are the package names, the values are the hashes of the values
for that object.

Example:

 #conf file
 define package Mail::Bulkmail
 
 use_envelope = 1
 safe_banned = 0
 
 define package Mail::Bulkmail::Server
 
 Smtp = your.smtp.com
 Port = 25
 
 $conf = {
 	'Mail::Bulkmail' => {
 		'use_envelope' => 1,
 		'safe_banned' => 1
 	},
 	'Mail::Bulkmail::Server' => {
 		'Smtp' => 'your.smtp.com',
 		'safe_banned' => 1
 	}
 };
 
read_conf_file is called at object initialization. Any defaults for your object are read in at this time.
You'll rarely need to read the conf file yourself, since at object creation it is read and parsed and the values passed
on.

Note that it will combine the conf file in with an existing conf hash. To get a fresh one, pass in the conf_hash parameter.

Basset::Object->read_conf_file('conf_hash' => {});

B<Be sure to read up on the conf file structure, below>

The conf file is only re-read if it has been modified since the last time it was read.

=cut

our $conf = {};
our $loaded = {};

sub conf {
	return $conf;
}

sub loaded {
	return $loaded;
}
	
sub read_conf_file {
	my $class = shift;
	
	#this is a major league hack. Since Basset::Object::Conf isa Basset::Object, we wait
	#until now to set its inheritance. Basset::Object::Conf should never be instantiated, so it's
	#not an issue. The first time read_conf_file is called, we set this to be a Basset::Object.
	#
	#This way, we can successfully compile this module first, and have Basset::Object use it.
	unless (@Basset::Object::Conf::ISA) {
		require Basset::Object;
		@Basset::Object::Conf::ISA = qw(Basset::Object);
	}

	my %init = @_;
	
	if (defined $init{'conf_files'} && ! ref $init{'conf_files'}) {
		$init{'conf_files'} = [$init{'conf_files'}];
	}

	my @confs	= reverse($init{'conf_files'} ? @{$init{'conf_files'}} : $class->conf_files);
	my $conf	= $init{'conf_hash'} ? $init{'conf_hash'} : $class->conf;

	$conf->{$default_package}->{'types'}->{'conf'} = $class;

	foreach my $conf_file (@confs){
		next unless -e $conf_file ;

		if (! $class->loaded->{$conf_file} || -M $conf_file < $class->loaded->{$conf_file} || @_){

			my $pkg	 = $default_package;

			my $handle = $class->gen_handle;

			open ($handle, $conf_file) || next;
			while (my $line = <$handle>) {

				next if ! defined $line || $line =~ /^\s*#/ || $line =~ /^\s*$/;
				
				if ($line =~ /^define package\s+(\S+)/){
					$pkg = $1;
					next;
				};
				
				if ($line =~ /^include file\s+(\S+)/) {
					my $subconf = $class->read_conf_file($1);
					foreach my $pkg (keys %$subconf) {
						my $pkgconf = $conf->{$pkg};
						my $subpkgconf = $subconf->{$pkg};
						@$pkgconf{keys %$subpkgconf} = values %$subpkgconf;
					};
					next;
				};
				
				$line =~ s/(?:^\s+|\s+$)//g;
				$line =~ /^(?:\s*(\d+)\s*:)?\s*([-+]?\w+)\s*([@%]?)=\s*(.+)/
					or return $class->error("Invalid conf file : $line", "BOC-02");

				my ($user, $key, $ref, $val) = ($1, $2, $3, $4);

				unless (defined $val){
					($user, $key, $ref, $val) = ($user, $key, undef, $ref);
				};
				
				unless (defined $ref){
					($user, $key, $ref, $val) = (undef, $user, $ref, $key);
				};

				($user, $key, $val) = (undef, $user, $key) unless defined $val;
				
				next if defined $user && $user != $>;
				
				$val = undef if $val eq 'undef';

				$val = eval qq{return "$val"} if defined $val && $val =~ /^\\/;
				
				if ($ref) {
					if ($ref eq '@') {
						$conf->{$pkg}->{$key} ||= [];
						push @{$conf->{$pkg}->{$key}}, $val;
					} elsif ($ref eq '%') {
						$conf->{$pkg}->{$key} ||= {};
						my ($k, $v) = split(/\s*=\s*/, $val);
						$conf->{$pkg}->{$key}->{$k} = $v;
					}
				}
				else {
					$conf->{$pkg}->{$key} = $val;
				};
			};	#end while
			close $handle;
			
			#this is an irritating hack. In order to notify, types needs to be defined
			#and chances are, this is the first place we'd define it due to circular inheritance
			#issues.
				
			unless (! $class->loaded->{$conf_file}) {
				Basset::Object->add_trickle_class_attr('types')
					unless Basset::Object->can('types');
				$class->notify('ConfFileReRead', $conf_file);
			}

			$class->loaded->{$conf_file} = -M $conf_file unless @_;
		};	#end if
	};	#end foreach
	return $conf;
	
};	#end sub

1;

__END__

=pod

=back

=head1 CONF FILE specification

Your conf files are very important. You did specify them up in the @conf_files list above, right? Of course you did.

But now you need to know how they look. They're pretty easy.

Each line of the conf file is a name = value pair.

 ERRFILE = /path/to/err.file

Do not put the value in quotes, or they will be assigned.

 ERRFILE = /path/to/err.file		#ERRFILE is /path/to/err.file
 ERRFILE = "/path/to/err.file"		#ERRFILE is "/path/to/err.file"

the conf file is analyzed by the object initializer, and then each value is passed to the appropriate object upon
object creation. So, in this case your ERRFILE class_attribute would be set to ERRFILE leading and trailing whitespace
is stripped.

 so these are all the same:
 ERRFILE = /path/to/err.file
    ERRFILE        =     /path/to/err.file
            ERRFILE =        /path/to/err.file            
            										^^^^^extra spaces

Sometimes it is insufficient to have only one conf file, but inappropriate to add more to the conf_files
array. In these cases, it is best to use the include file directive.

include file subconf.cfg

When an include file directive is encountered, processing of the current conf file is suspended and the
subfile is read in and processed first. After it is finished, the current file continues as before. This
is best used in conjunction with the user restriction options to have one single global conf file
that points to multiple different user files, allowing each user to configure his own options as appropriate.

Your conf file is read by read_conf_file. As you saw in the docs for read_conf_file, it creates a hashref. The top
hashref has keys of package names, and the conf->{package} hashref is the name value pairs. To do that, you'll need
to define which package you're looking at.

 define package SomeClass

 define package OtherClass
 
 ERRFILE = /path/to/err.file
 
So ERRFILE is now defined for OtherClass, but not for SomeClass (unless of course, OtherClass is a sub-class of
SomeClass)

If you do not define a package, then the default package is assumed.

Multiple entries in a conf file take the last one.

 define package SomeClass
 
 ERRFILE = /path/to/err.file
 ERRFILE = /path/to/err.other.file
 
so SomeClass->ERRFILE is /path/to/err.other.file There is no way to programmatically access /path/to/err.file, the
value was destroyed, even though it is still in the conf file.

There is one magic value token...undef

 ERRFILE = undef
 
This will set ERRFILE to the perl value 'undef', as opposed to the literal string "undef"

Sometimes, you will want to give a conf entry multiple values. Then, use the @= syntax.

 define package SomeClass
 
 foo = 7
 bar @= 8
 bar @= 9
 
SomeClass->foo will be 7, SomeClass->bar will be [8, 9]

Also, you may sometimes wish to specify a hash table in the conf file. In that case, use the %= syntax.

 define package SomeClass
 
 baz %= this=those
 baz %= him=her
 baz %= me=you

SomeClass->baz will be {this => those, him => her, me => you}

There is no way to assign a value more complex than a scalar, arrayref, or hashref.

Comments are lines that begin with a #

 #enter the SomeClass package
 define package SomeClass

 #connections stores the maximum number of connections we want
 connections = 7
 

If you want to get *really* fancy, you can restrict values to the user that is running the script. Use
the :ID syntax for that.

 define package SomeClass
 
 #user 87 gets this value
 87:foo	= 9
 
 #user 93 gets this value
 93:foo = 10
 
 #everyone else gets this value
 foo = 11
 
=head1 SAMPLE CONF FILE

 #this is in the default package
 ERRFILE = /path/to/err.file
 
 define package Mail::Bulkmail::Server
 #set our Smtp Server
 Smtp	= your.smtp.cpm
 
 #set our Port
 Port	= 25
 
 define package Basset::SubClass
 
 #store the IDs of the server objects we want to use by default
 
 servers @= 7
 servers @= 19
 servers @= 34

Object attributes must be prepended with a '-' sign. This is syntax swiped from objective-C. In Objective-C, class methods
begin with a "+" and object methods begin with a "-".

 #set class attribute foo to 7
 foo	= 7
 
 #set object attribute bar to 8
 -bar	= 8

Basset::Object's initializer requires the prepending '-'. This is used for objects that should receive a default value of
some sort from the conf file. Values not prepending with a '-' will not be called by the object initializer when new objects
are created.

=head1 GRAMMAR

In fact, we'll even get fancy, and specify an ABNF grammar for the conf file.

	CONFFILE = *(LINE)					; a conf file consists of 0 or more lines
	
	LINE = (
			DEFINE 			; definition line
			/ INCLUDE		; include line
			/ COMMENT 		; comment line
			/ EQUATION 		; equation line
			/ *(WSP)		; blank line
		) "\n"				; followed by a newline character
	
	DEFINE = "define package" TEXT
		
	INCLUDE = "include file" TEXT
			
	COMMENT = *(WSP) "#" TEXT
	
	EQUATION = *(WSP) (VARIABLE / USER_VARIABLE) 0*1("-") *(WSP)
		(EQUATION_SYMBOL *(WSP) VALUE *(WSP) / "%=" *(WSP) VARIABLE *(WSP) "=" *(WSP) VALUE)
	
	USER_VARIABLE = USER *(WSP) ":" *(WSP) VARIABLE
	
	USER = 1*(DIGIT)
	
	EQUATION_SYMBOL = "=" / "@="
	
	VALUE = *(TEXT)
	
	VARIABLE = *(TEXT)
	
	TEXT = VISIBLE *(VISIBLE / WSP) [VISIBLE]
	
	VISIBLE = %d33-%d126	; visible ascii characters


=head1 SEE ALSO

Also see Basset::Object, Basset::Object::Persistent

=head1 COPYRIGHT (again)

Copyright and (c) 2002 James A Thomason III (jim@jimandkoka.com). All rights reserved.
Basset::Object::Conf is distributed under the terms of the Perl Artistic License, except for items where otherwise noted.

=head1 CONTACT INFO

So you don't have to scroll all the way back to the top, I'm Jim Thomason (jim@jimandkoka.com) and feedback is appreciated.
Bug reports/suggestions/questions/etc.  Hell, drop me a line to let me know that you're using the module and that it's
made your life easier.  :-)

=cut


=cut
