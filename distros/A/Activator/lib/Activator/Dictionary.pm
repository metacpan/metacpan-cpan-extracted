package Activator::Dictionary;
use strict;

use Activator::DB;
use Activator::Registry;
use Activator::Exception;
use Activator::Log qw( :levels );
use Exception::Class::TryCatch;
use Data::Dumper;
use base 'Class::StrongSingleton';

=head1 NAME

Activator::Dictionary

=head1 SYNOPSIS

Configure your dictionary using Activator::Registry. See
L<CONFIGURATION OVERVIEW> below.

Using explicit realms and languages:

  use Activator::Dictionary;
  my $dict = Activator::Dictionary->get_dict( $lang );
  my $val  = $dict->lookup( $key, $realm );

Or, configure defaults in Activator::Registry config file:

  'Activator::Registry':
    'Activator::Dictionary':
      default_lang:  'en'
      default_realm: 'my_realm'

Then:

  use Activator::Dictionary;
  my $dict = Activator::Dictionary->get_dict();
  my $val  = $dict->lookup( $key );

=head1 DESCRIPTION

This module provides simple lookup of key/value pairs for intended for
internationalization/localization(I18N/L10N). It is also useful for
separating the progamming of a project from the creation of the text
used by it. The object created by this module is a per-process
singleton that uses dictionary definintions from a simple
space-delimeted file or database table(s). The dictionary is
completely maintained in memory and loads realms and languages
dynamically on an as-needed basis, so this module may not be
appropriate for extremely large lexicons or for projects that create
large numbers of program instances. That being said, it can be
relatively memory efficient when used for a single language deployment
in an application that provides multiple language support.

An C<Activator::Dictionary> object can have multiple realms: that is, you
could have a 'web' dictionary for the website text, an 'error'
dictionary for backend job messages, and any number of other realms
needed for your application. This allows you to separate the
translatable texts from each other so that, for example, the web
frontend of your application could give a user friendly message using
the 'web' realm, and the backend could use the 'error' realm to log
something much more useful to a technician.

Note that there can be great amounts of complexity localizing language
within an application. This module is for the simple cases, where you
just have key/value lookups. If you need complex conjugations, object
sensitive pluralization, you should look into the existing
L<Locale::Maketext>, or the upcoming L<Activator::Lexicon> module. It
is highly recommended that you read
L<http://search.cpan.org/dist/Locale-Maketext/lib/Locale/Maketext/TPJ13.pod>
before making a decision as to which localization method your
application needs.

=head1 CONFIGURATION OVERVIEW

  'Activator::Registry':          # uses Activator::Registry
    'Activator::Dictionary':
      default_lang:  'en'         # default language for get_dict()*
      default_realm: 'my_realm'   # default realm for lookup()*
      fail_mode:     [ die ]      # die instead of returning undef
                                    for lookup failures*
      dict_files:    '<path>'     # path to definition files**
      dict_tables:   [ t1, t2 ]   # database definition table(s)**
      db_alias:      'db'         # Activator::DB alias to use***

   * optional
  ** either dict_files OR dict_tables MUST be defined
 *** db_alias required when dict_tables defined

=head1 DICTIONARY FILE CONFIGURATION

Configure your dictionary in your project registry:

  'Activator::Registry':
    'Activator::Dictionary':
      dict_files:         '/path/to/definitions/files'

Then create dictionary definition files for realms in the dictionary
path as such:

 <dict_files path>/<lang>/<realm>.dict

=head2 Dictionary File Format

To create a dictionary file, create a file named C<E<lt>realmE<gt>.dict>
containing key/value pairs separated by whitespace. Keys can have any
non-whitespace character in them. The amount of whitespace between key
and value can be any length and can be tab or space characters (more
specifically, any character that matches C</\s/>). Keys and values must
be on the same line.

For example:

  error.bummer        A bummer of an error occured
  foo-html            <p>this is the foo paragraph</p>
  welcome_msg         Welcome to Activatory::Dictionary!!
  answer              42

Empty lines and any line that the first non-whitespace character is
C<#> will be ignored. Leading whitespace for keys will be ignored as
well, so that you can indent however you see fit.

Leading and trailing whitespace are stripped from values. If the value
for some key must begin or end with white space, wrap the value
portion of the line with double quotes. Any value that begins with a
double quote will have a trailing double quote stripped.

Examples:
   key1 value1                # value eq 'value1'
   # key2 value2              # ignored
       # key3 value3          # ignored
                              # ignored
     key4 multiple words      # value eq 'multiple words'
   key5 "  value5 is quoted"  # value eq '  value5 is quoted'
   key6 ""OMG!" "quotes!""    # value eq '"OMG!" "quotes!"'
   key7 " whitespaced "       # value eq ' whitespaced '

=head1 DATABASE CONFIGURATION

If you would rather that your dictionary definitions are in a database,
or need more complex values than can be reasonably contained within a
single line, create a table of any name with this schema:

 CREATE TABLE db_table_name (
   # primary column must end with '_id'
   *_id          serial,
   lang          enum('en','de','es') default 'en',
   realm         text NOT NULL,
   key_prefix    text NOT NULL,
   last_modified datetime NOT NULL,

   # Then, define any attributes of the key that you any way you want,
   # excepting that they cannot end with the string '_id', or be the
   # same as any of the cols in the above section (aka: the previous
   # columns use reserved words):
   col_1 varchar(256) NOT NULL,
   col_2 text NOT NULL,
   col_3 text NOT NULL,
   col_4 int,
   col_5 text,

   # insure realm/key/lang integrity in your DB's way. This is MySQL:
   UNIQUE KEY IDX_db_dictionary_1 (realm,key_prefix,lang)
 );

The schema is designed to allow all realms to be in one table, but you
can spread it accross as many tables as you like, provided they are in
the same database.

NOTE: When using database for definitions C<key_prefix> cannot have a
period in it.

Add the table(s) to use to the registry:

  'Activator::Registry':
    'Activator::Dictionary':
      dict_tables: [ table1, table2 ]
      db_alias: 'Activator::DB alias to use'

Note that you can use dict_files and dict_tables in any combination.

=head1 RESERVED WORDS FOR REALMS

When naming realms, follow these guidelines:

=over

=item *

Use more than 2 characters, to not confuse realms with languages.

=item *

Do not use the word C<config> for a realm

=back

TODO: enforce this guidance programatically

=head1 LOOKUP FEATURES

=head2 Using a Default Realm and/or Language

In some applications, it is inconvenient to have to pass the realm as
an argument for every lookup call when there is one common realm that
is nearly always used. You can define a default language and/or realm
as such:

  'Activator::Registry':
    'Activator::Dictionary':
      default_lang:  'en'         # optional
      default_realm: 'my_realm'   # optional

Not passing the C<$lang> or C<$realm> arguments will then use the registry
key(s):

  my $dict = Activator::Dictionary->get_dict();  # sets lang to en
  $dict->lookup( $key );                         # returns 'my_realm' value

=head2 Database Dictionary Lookups

When using database dictionary definitions, you must define the target
field you are interested in with dot notation:

  $dict->lookup( $key_prefix );        # fails
  $dict->lookup( "$key_prefix.$col" ); # succeeds

For this reason, it is required that you not use period in the
C<key_prefix> column.

=head2 Failure Mode

Instead of returning undef for non-existent keys, you can configure
this module to fail via one or more of these methods:

  die     : throws Activator::Exception::Dictionary('key', 'missing')
  key     : returns the requested key itself
  ''      : returns empty string
  <lang>  : return the value for <lang> in the requested realm
  <realm> : return the value for <realm>

Examples:

  $db->lookup( $key, $realm1 );  # value does not exist

  fail_mode: [ realm2, de, key ]

   return value for $key in realm2 if it exists
   return value for $key in realm1 in german if it exists
   return $key

  fail_mode: [ realm2, die ]

   return value for $key in realm2 if it exists
   throw Activator::Exception::Dictionary

  fail_mode: [ realm2, realm3 ]

   return value for $key in realm2 if it exists
   return value for $key in realm3 if it exists
   return undef (fallback to default failure mode)

  fail_mode: [ '' ]

   return empty string

=head1 DISABLING LOAD WARNING

When loading dictionary files, you may sometimes see:

  [WARN] Couldn't load dictionary from file for <lang>

If you are using files for one language, and the DB for another, this
could get really annoying since you KNOW THIS TO BE TRUE. The
workaround is to set the log level for this message an alternate level
of FATAL, ERROR, WARN, INFO, DEBUG, or TRACE. For example:

  $dict->{LOG_LEVEL_FOR_FILE_LOAD} = 'INFO';

=head1 METHODS

=head2 lookup($key, $realm)

OO Usage:

  my $dict = Activator::Dictionary->get_dict( $lang );
  $dict->lookup( $key, $realm );
  $dict->lookup( $key2, $realm );

Static Usage:

  Activator::Dictionary->use_lang( $lang );
  Activator::Dictionary->lookup( $key, $realm );
  Activator::Dictionary->lookup( $key2, $realm );

Returns the value for C<$key> in C<$realm>. Returns C<undef> when the
key does not exist, but you can configure this module to do something
different (see L<Failure Mode> below). If realm does not exist, throws
C<Activator::Exception::Dictionary> no matter the failure mode.

=cut

sub lookup {
    my ($pkg, $key, $realm ) = @_;
    my $self = &get_dict( $pkg );

    my $lang = $self->{cur_lang};

    $realm ||= $self->{config}->{default_realm};

    if ( !defined( $key ) ) {
	Activator::Exception::Dictionary->throw( 'key', 'undefined');
    }

    if ( !exists( $self->{ $lang }->{ $realm } ) ) {
	Activator::Exception::Dictionary->throw( 'realm', 'undefined', $realm);
    }

    if ( exists( $self->{ $lang }->{ $realm }->{ $key } ) ) {
	my $ret = $self->{ $lang }->{ $realm }->{ $key };
	DEBUG( "Found key '$key'. value: $ret");
	return $ret;
    }

    # At this point, there was no value for the given key in the given
    # realm. Honor configured failure mode.
    DEBUG( "Didn't find key '$key'.");
    if ( !exists( $self->{config}->{fail_mode} ) ) {
	DEBUG( "No fail_mode defined. Returning undef");
	return;
    }

    if ( !defined( $self->{config}->{fail_mode} ) ) {
	DEBUG( "No fail_mode defined. Returning undef");
	return;
    }

    my %tried = ( $lang => 1, $realm => 1 );
    my @modes = @{ $self->{config}->{fail_mode} };
    DEBUG( "Trying modes: ". Dumper( \@modes ) );
    foreach my $mode ( @modes ) {
	next if $tried{ $mode };
	$tried{ $mode } = 1;
	DEBUG( "Trying fail_mode '$mode'");
	if ( $mode eq 'die' ) {
	    DEBUG( "die means throw exception");
	    Activator::Exception::Dictionary->throw('key', 'missing');
	}

	if ( $mode eq '' ) {
	    DEBUG( "returning empty string");
	    return '';
	}

	if ( $mode eq 'key' ) {
	    DEBUG( "returning key '$key'");
	    return $key;
	}

	# check realms
	if ( grep /^$mode$/, keys( %{ $self->{ $lang } } ) ) {
	    if ( !exists( $self->{ $lang }->{ $mode }->{ $key } ) ) {
		next;
	    }
	    DEBUG( "Found entry for realm '$mode'");
	    return $self->{ $lang }->{ $mode }->{ $key };
	}

	# check langs
	if ( grep /^$mode$/, keys( %$self ) ) {
	    if ( !exists( $self->{ $mode }->{ $realm } ) ) {
		next;
	    }
	    if ( !exists( $self->{ $mode }->{ $realm }->{ $key } ) ) {
		next;
	    }
	    DEBUG( "Found entry for lang '$mode'");
	    return $self->{ $mode }->{ $realm }->{ $key };
	}
    }
    DEBUG( "No valid fail_mode found. Returning undef");
    return;
}

=head2 get_dict( $lang )

Returns a reference to the Activator::Dictionary object. Sets all
future lookups to use the $lang passed in. If $lang is not passed in,
uses 'Activator::Dictionary' registry value for 'default_lang'. If
$lang cannot be determined, throws Activator::Exception::Dictionary.

=cut

sub get_dict {
    my ($pkg, $lang ) = @_;
    my $self = &new( @_ );

    # first call
    if( !exists $self->{config} ) {
	$self->_init_config();
    }

    # first call for $lang
    $lang ||= $self->{cur_lang} || $self->{config}->{default_lang};

    if ( !$lang ) {
	Activator::Exception::Dictionary->throw( 'lang', 'undefined' );
    }

    if( !exists $self->{ $lang } ) {
	try eval {
	    $self->_init_lang( $lang );
	};
	if ( catch my $e ) {
	    Activator::Exception::Dictionary->throw( 'init_lang', 'failed', $e );
	}

    }

    $self->{cur_lang} = $lang;

    return $self;
}

=head2 new( $lang )

Creates a dictionary object. Not very useful, as all it does is create
an uninitialized instance of an Activator::Dictionary object.

=cut

# Contstructor. Implements singleton.
sub new {
    my ( $pkg, $lang ) = @_;

    my $self = bless( { LOG_LEVEL_FOR_FILE_LOAD => 'WARN' }, $pkg);

    $self->_init_StrongSingleton();

    return $self;
}

sub _init_config {
    my ($self) = @_;

    # old config format
    my $config = Activator::Registry->get('Activator::Dictionary');
    if ( !$config ) {
	# new format
	$config = Activator::Registry->get('Activator->Dictionary');
    }


    $self->{config}->{default_realm} = $config->{default_realm} || 'default';
    $self->{config}->{default_lang}  = $config->{default_lang} || 'en';
    $self->{config}->{dict_tables}   = $config->{dict_tables};
    $self->{config}->{dict_files}    = $config->{dict_files};
    $self->{config}->{db_alias}      = $config->{db_alias};
    $self->{config}->{fail_mode}     = $config->{fail_mode};

    if ( !( defined( $self->{config}->{dict_files} ) ||
	    defined( $self->{config}->{dict_tables} )
	  ) ) {
	Activator::Exception::Dictionary->throw( 'tables_or_files', 'undefined' );
    }

    if ( defined( $self->{config}->{dict_tables} ) &&
	 !defined( $self->{config}->{db_alias} ) ) {
	Activator::Exception::Dictionary->throw( 'db_alias', 'missing' );
    }
}

sub _init_lang {
    my ($self, $lang) = @_;
    my $processed = 0;

    # import all the realms for this language from the db
    if ( defined( $self->{config}->{dict_tables} ) ) {
	my ( $sql, $rows, $row, $col, $realm, $key );
	foreach my $table ( @{ $self->{config}->{dict_tables} } ) {
	    $sql = "SELECT * FROM $table WHERE lang = ?";
	    try eval {
		$rows = Activator::DB->getall_hashrefs( $sql, [ $lang ], connect => 'def' );
	    };
	    if ( catch my $e ) {
		Activator::Exception::Dictionary->throw( 'dict_tables',
							 'misconfigured',
							 "Activator::Dictionary caught: \n$e" );
	    }
	    foreach $row ( @$rows ) {
		foreach $col ( keys %$row ) {
		    if ( $col !~/_id$|realm|lang|key_prefix|last_modified/ ) {
			$realm = $row->{realm};
			$key   = "$row->{key_prefix}.$col";
			if ( exists( $self->{ $lang }->{ $realm }->{ $key } ) ) {
			    local $Log::Log4perl::caller_depth;
			    $Log::Log4perl::caller_depth += 3;
			    WARN( "dictionary table $table redefines value for realm '$realm' key_prefix '$row->{key_prefix}' column '$col'");
			}
			$self->{ $lang }->{ $realm }->{ $key } =
			  $row->{ $col };
		    }
		}
	    }
	    $processed = 1;
	}
    }

    # import all the realms for this lang from files
    if ( defined( $self->{config}->{dict_files} ) ) {
	my $dir_loc = $self->{config}->{dict_files};
	$dir_loc =~ s|/$||;
	$dir_loc .= "/$lang";

	if (!opendir( DIR, $dir_loc ) ) {
	    local $Log::Log4perl::caller_depth;
	    $Log::Log4perl::caller_depth += 3;

	    # This message could be annoying in some situations, so
	    # allow changing the log level for just this one.
	    my $msg = "Couldn't load dictionary from file for $lang from $dir_loc";
	    my $level = $self->{LOG_LEVEL_FOR_FILE_LOAD};
	    if ( $level =~ /FATAL|ERROR|WARN|INFO|DEBUG|TRACE/ ) {
		no strict 'refs';
		&$level( $msg );
	    }
	    else {
		WARN( $msg );
	    }
	}
	else {

	    my @files = grep { /^[^\.]/ && -f "$dir_loc/$_" } readdir(DIR);
	    closedir DIR;
	    my ($file, $realm, $key, $value);
	    foreach $file ( @files ) {
		if ( $file !~ /.dict$/ ) {
		    WARN("Non-dictionary file '$file' found in lang dir $dir_loc");
		    next;
		}

		open DICT, "<$dir_loc/$file" ||
		  Activator::Exception::Dictionary->throw('dict_file',
							  'unreadable',
							  "$dir_loc/$file" );
		$file =~ /(.+)\.dict$/;
		$realm = $1;

		while (<DICT>) {
		    chomp;
		    next if /^\s*$/;
		    next if /^\s*#/;
		    s/^\s+//;
		    s/\s+$//;
		    ($key, $value) = split /\s+/, $_, 2;
		    $value =~ s/("$)//;
		    if ( $1 ) {
			$value =~ s/^"//;
		    }
		    $self->{ $lang }->{ $realm }->{ $key } = $value;
		}
		close DICT;
		$processed = 1;
	    }
	}
    }
    return $processed;
}

=head1 SEE ALSO

L<Activator::Log>, L<Activator::Exception>, L<Activator::DB>,
L<Exception::Class::TryCatch>, L<Class::StrongSingleton>

=head1 AUTHOR

Karim A. Nassar

=head1 COPYRIGHT

Copyright (c) 2007 Karim A. Nassar <karim.nassar@acm.org>

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=cut

1;
