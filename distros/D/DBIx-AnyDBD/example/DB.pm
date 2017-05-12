# $Id: DB.pm,v 1.2 2002/01/08 11:15:28 matt Exp $

package Example::DB;
use strict;

use DBIx::AnyDBD 1.98;

use vars qw($DB);
use constant MAX_ATTEMPTS => 32;

# class attributes
foreach my $att ( qw( dsn user password connect_attributes ) )
{
    eval "
{
    my \$$att;
    sub set_$att {
        shift; # class name
        \$$att = shift;
    }
    sub $att {
        return \$$att;
    }
}
";
}

sub instance {
    if ($DB && $DB->ping) {
        # rollback uncommited transactions
        # this doesn't work where multiple nested method calls might call instance()
        # $DB->rollback;
        
        return $DB;
    }

    my $class = shift;
    
    my $x = 0;
    do {
	if ($DB) {
            eval { $DB->disconnect; };
            undef $DB;
	}
        $class->connect;
        return $DB if $DB && $DB->ping
    } until ($x++ > MAX_ATTEMPTS);

    die "Couldn't connect to database";
}

sub connect {
    my $class = shift;

    $DB = DBIx::AnyDBD->new( dsn => $class->dsn,
			   user => $class->user,
			   pass => $class->password,
			   attr => $class->connect_attributes,
			   package => $class,
			 );
}

sub DESTROY {
    $DB->disconnect if $DB && ref $DB;
}

1;

__END__

=head1 NAME

Example::DB - Example class for DBIx::AnyDBD usage

=head1 SYNOPSIS

  use Example::DB
  Example::DB->set_dsn('dbi:Pg:dbname=foo');
  Example::DB->set_user('matt');
  Example::DB->set_password('blueberry');
  
  my $db = Example::DB->instance();
  
  my @users = $db->get_users(); # called from Example/DB/Pg.pm
  
  # NB: This is just an example. It is designed not for usage,
  #     but so that you read the source code!

=head1 DESCRIPTION

This is a couple of example class files that you can use and adapt in
projects that use DBIx::AnyDBD. It is here as an B<example> only, and
not meant to be used as-is. That means you should copy the code into
your own class hierarchy, rather than use it as Example::*.

The methods of most interest are those in DB/*.pm. These implement the
database specific routines for each database. They encapsulate various
things about each database, such as the ability to do nested transactions,
how to retrieve the current id value for a table, and how dates are
encapsulated. For most purposes you should put your SQL inside the
Default.pm file, and only put stuff in the database specific files when
necessary.

Most of the code in these files is originally by Dave Rolsky, with
thanks.

=cut
