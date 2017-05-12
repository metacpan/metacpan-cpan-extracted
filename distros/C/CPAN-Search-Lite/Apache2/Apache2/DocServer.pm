package Apache2::DocServer;
use strict;
use warnings;
use DBI;
use File::Spec::Functions;
use CPAN::Search::Lite::Query;
use mod_perl 1.999022;     # sanity check for a recent version
use Apache2::Const -compile => qw(OK REDIRECT SERVER_ERROR 
                                 TAKE1 RSRC_CONF ACCESS_CONF);
use Apache2::Module ();
use Apache2::RequestRec ();
our $VERSION = 0.77;

my @directives = (
                  {name      => 'DocServer_db',
                   errmsg    => 'database name',
                   args_how  => Apache2::Const::TAKE1,
                   req_override => Apache2::Const::RSRC_CONF | Apache2::Const::ACCESS_CONF,
                  },
                  {name      => 'DocServer_user',
                   errmsg    => 'user to log in as',
                   args_how  => Apache2::Const::TAKE1,
                   req_override => Apache2::Const::RSRC_CONF | Apache2::Const::ACCESS_CONF,
                  },
                  {name      => 'DocServer_pod_root',
                   errmsg    => 'root directory of pod files',
                   args_how  => Apache2::Const::TAKE1,
                   req_override => Apache2::Const::RSRC_CONF | Apache2::Const::ACCESS_CONF,
                  },
                  {name      => 'DocServer_passwd',
                   errmsg    => 'password for user',
                   args_how  => Apache2::Const::TAKE1,
                   req_override => Apache2::Const::RSRC_CONF | Apache2::Const::ACCESS_CONF,
                  },
                  {name      => 'DocServer_max_results',
                   errmsg    => 'maximum number of results',
                   args_how  => Apache2::Const::TAKE1,
                   req_override => Apache2::Const::RSRC_CONF | Apache2::Const::ACCESS_CONF,
                  },
                 );
Apache2::Module::add(__PACKAGE__, \@directives);

my ($query, $cfg, $r, $max_results);

sub get_doc {
  my ($class, $mod) = @_;
  $mod =~ s!(\.pm|\.pod)$!!;
  return unless ($mod =~ m!^[\w:\.\-]+$!);
  $r = Apache->request;
  $cfg = Apache2::Module::get_config(__PACKAGE__, 
                                    $r->server,
                                    $r->per_dir_config) || { };

  $max_results ||= $cfg->{max_results} || 200;
  $query ||= CPAN::Search::Lite::Query->new(db => $cfg->{db},
                                            user => $cfg->{user},
                                            passwd => $cfg->{passwd},
                                            max_results => $max_results);
  my $fields = [qw(doc dist_name)];
  $query->query(mode => 'module', name => $mod, fields => $fields);
  my $results = $query->{results};
  return unless $results;
  my ($doc, $dist_name) = ($results->{doc}, $results->{dist_name});
  return unless ($doc and $dist_name);
    
  my $base = catfile $cfg->{pod_root}, $dist_name, (split '::', $mod);
  my $file;
  for my $ext ('.pm', '.pod') {
    my $trial = $base . $ext;
    if (-f $trial) {
      $file = $trial;
      last;
    }
  }
  return unless $file;
  open (my $fh, $file) or return;
  my @lines = <$fh>;
  close $fh;
  return \@lines;
}

sub get_readme {
  my ($class, $dist) = @_;
  return unless ($dist =~ m!^[\w:\.\-]+$!);
  $r ||= Apache->request;
  $cfg ||= Apache2::Module->get_config(__PACKAGE__, 
                                      $r->server,
                                      $r->per_dir_config) || { };
  
  $max_results ||= $cfg->{max_results} || 200;
  $query ||= CPAN::Search::Lite::Query->new(db => $cfg->{db},
                                            user => $cfg->{user},
                                            passwd => $cfg->{passwd},
                                            max_results => $max_results);
  my $fields = [qw(readme)];
  $query->query(mode => 'dist', name => $dist, fields => $fields);
  my $results = $query->{results};
  return unless ($results and $results->{readme});
  
  my $file = catfile $cfg->{pod_root}, $dist, 'README';
  return unless (-f $file);
  open (my $fh, $file) or return;
  my @lines = <$fh>;
  close $fh;
  return \@lines;
}

sub DocServer_db {
  my ($cfg, $parms, $db) = @_;
  $cfg->{ db } = $db;
}

sub DocServer_user {
  my ($cfg, $parms, $user) = @_;
  $cfg->{ user } = $user;
}

sub DocServer_passwd {
  my ($cfg, $parms, $passwd) = @_;
  $cfg->{ passwd } = $passwd;
}

sub DocServer_max_results {
  my ($cfg, $parms, $max_results) = @_;
  $cfg->{ max_results } = $max_results;
}

sub DocServer_pod_root {
  my ($cfg, $parms, $pod_root) = @_;
  $cfg->{ pod_root } = $pod_root;
}


1;

__END__

=head1 NAME

Apache2::DocServer - mod_perl 2 soap server for soap-enhanced perldoc

=head1 DESCRIPTION

This module provides a mod_perl 2 soap-based service to
C<Pod::Perldocs>. The necessary Apache2 directives are

 PerlLoadModule Apache2::DocServer

 DocServer_db database_name
 DocServer_user user_name
 DocServer_passwd password_for_above_user
 DocServer_pod_root "/Path/to/pod/root"

 <Location /docserver>
   SetHandler perl-script
   PerlResponseHandler Apache2::SOAP
   PerlSetVar dispatch_to "D:/Perl/site/lib/Apache2, Apache2::DocServer"
 </Location>

where C<Apache::SOAP> is included in version 0.69 and above of
the C<SOAP::Lite> distribution. See the C<perldocs> script in
this distribution for an example of it's use.

=head1 SEE ALSO

L<Pod::Perldocs>.

=cut
