# $Id: Shorten.pm,v 1.4 2003/09/10 07:28:54 cvspub Exp $

package CGI::Shorten;
use strict;
our $VERSION = '0.02';

use CGI;
our $cgi = new CGI;
our @dbs = qw(lndb);

use DB_File;
use Fcntl ':flock';
use Math::String;

# ----------------------------------------------------------------------
sub new {
    my $pkg = shift;
    my %arg = @_;
    my $db_prefix = $arg{db_prefix} or die "Please specify the prefix of the databases\n";
    my $self = {
	_db_prefix => $db_prefix,
	_config_file => $db_prefix."_conf",
	_script_url => $arg{script_url} || 'http://127.0.0.1/shorten.pl',
    };

    if(!-e$self->{_config_file}){
	open CONF, '>', $self->{_config_file};
	close CONF;
    }

    if(open CONF, $self->{_config_file}){
	flock(CONF,LOCK_EX);
	my $line;
	if(chomp($line=<CONF>)){
	    $self->{_id} = new Math::String $line;
	}
	flock(CONF,LOCK_UN);
	close CONF;
    }
    $self->{_id} ||= new Math::String 'a';

    foreach my $db (@dbs){
	tie
	    %{$self->{'_'.$db}} => 'DB_File',
	    $db_prefix."_$db", O_CREAT | O_RDWR, 0644,
	    $DB_BTREE;
    }

    bless $self => $pkg;
}

# ----------------------------------------------------------------------
use IO::Handle;
sub DESTROY {
    my $self = shift;
    foreach my $db (@dbs){
	untie %{$self->{'_'.$db}};
    }

    my $retval;
    do{
	if($retval = sysopen CONF, $self->{_config_file}, O_RDWR){

	    flock(CONF,LOCK_EX);
	    local $/;
	    my $line;
	    if(chomp($line=<CONF>)){
		my $id = new Math::String $line;
		$self->{_id} = $id if $id > $self->{_id};
	    }
	    seek(CONF, 0, 0);
	    print CONF $self->{_id}->bstr(), "\n";
	    flock(CONF,LOCK_UN);
	    close CONF;
	}
    }while(!$retval);

    undef $self->{_id};
}    

# ----------------------------------------------------------------------
sub shorten($$) {
    my ($self, $url) = @_;
    my $shurl = $self->{_script_url}.'?'.$self->{_id}->bstr();
    $self->{_lndb}->{$self->{_id}} = $url;
    $self->{_id}++;
    $shurl;
}

# ----------------------------------------------------------------------
sub lengthen($$) {
    my ($self, $url) = @_;
    if($url =~ s/^\Q$self->{_script_url}?\E//o ){
	return $self->{_lndb}->{$'};
    }
}

# ----------------------------------------------------------------------
sub redirect($$) {
    die "Where is your redirection url\n" unless $_[1];
    my $lnurl = $_[0]->lengthen($_[1]);
    return $lnurl ? $cgi->redirect($lnurl) : $cgi->header(-status=> '404'),
}



1;
__END__


=head1 NAME

CGI::Shorten - Creating your shortened links

=head1 SYNOPSIS

This module may help you to build a personal shortening-link service. Feeding the long, verbose, and tedious url, it can return you a shortened one. And it can also print out redirection header in you CGI script.

=head1 USAGE

  use CGI::Shorten;

=head2 new 

  $sh = new CGI::Shorten (
			  db_prefix => ".shorten_",
			  script_url => 'http://my.host/shorten.pl',
			  );

You need to specify the prefix of databases to the constructor and may specify the url of the script that does the shortening task. The script's url defaults to 'http://127.0.0.1/shorten.pl'


=head2 Return the shortened url

  print $sh->shorten($url);

=head2 return the original url

  print $sh->lengthen($url);

=head2 return the CGI redirection header

  print $sh->redirect($url);

If the redirected url does not exist, it will return 404 Not Found.

=head1 COPYRIGHT

xern E<lt>xern@cpan.orgE<gt>

This module is free software; you can redistribute it or modify it under the same terms as Perl itself.

=cut
