package Apache::Mysql;

use strict;
use Mysql();

my %Connected;

sub connect {
    my($self, @args) = @_;
    my $idx;
    if ($#args == -1) { 
	$idx = $self; 
    } else { 
	$idx = join (':', @args); 
    }
    return (bless $Connected{$idx}) if $Connected{$idx};

# only uncomment out the following line to see the connections in error_log 
#   print STDERR "Pid = $$, Apache::Mysql connect to $idx\n"; 

    $Connected{$idx} = Mysql->Connect(@args);
    return (bless $Connected{$idx});
}

sub DESTROY {
}

{ package Apache::Mysql;
  no strict;
  @ISA=qw(Mysql);
  use strict;
}


1;

__END__

=head1 NAME

Apache::Mysql - Initiate a persistent database connection to Mysql 

=head1 SYNOPSIS

 use Apache::Mysql;

 $dbh = Apache::Mysql->connect(...);

=head1 DESCRIPTION

This module supplies a persistent database connection to Mysql. You will need to have mysqlperl installed on your system. You should really use Apache::DBI instead of this module (this module was written when DBI::Mysql had problems, which have since been corrected).

This is the first version of the first module I have ever written, so expect errors! Any feedback or suggestions are gratefully received.

All you really need is to replace Mysql with Apache::Mysql. 
When connecting to a database the module looks if a database 
handle from a previous connect request is already stored. If 
not, a new connection is established and the handle is stored 
for later re-use. The destroy method has been intentionally 
left empty. 

=head1 SEE ALSO

Apache(3), Mysql(3)

=head1 AUTHORS
 
 MySQL and mysqlperl by Michael (Monty) Widenius <month@tcx.se> 
 mod_perl by Doug MacEachern <dougm@osf.org>
 Apache::Mysql by Neil Jensen <njensen@habaneros.com>


