# File: Comskil/JWand.pm
# Desc: A package that performs magic with remote JIRA services.

# #TODO Add in the sophisticated BEGIN/END package initialization blocks
# #TODO Add in the ability to log to a file.
# #TODO Run Perl Critic and Source code cleaner.


package Comskil::JWand;

=head1 NAME

Comskil::JWand - The great new Comskil::JWand!

=head1 VERSION

Version 0.1

=cut

use 5.006;
use strict;
use warnings;

our $VERSION    = "0.1";
our $COPYRIGHT  = "Copyright (c) 2011 Comskil, Inc.  All Rights Reserved Worldwide";
our $PRODUCT    = "Comskil::JWand";
our $USER_AGENT = "$PRODUCT\\$VERSION ($COPYRIGHT)";

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Comskil::JWand;

    my $foo = Comskil::JWand->new();
    ...
=cut

BEGIN {
    use Exporter;
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
	$VERSION = $Comskil::VERSION;
    @ISA = qw(Exporter);
    @EXPORT	= qw(
		buildProjectImportFile
    );
    @EXPORT_OK = qw(
		getDebug
		getVerbose
		setDebug
		setVerbose
    	grabPriorities
    	grabProjectRoles
    	grabResolutions
    	grabStatuses
    	grabAttachments
    	grabComponents
    	grabProjectInfo
    	grabServerInfo
    	grabVersions
    );
    %EXPORT_TAGS = ( 
    	ALL => [ qw(
			buildProjectImportFile
			getDebug
			getVerbose
			setDebug
			setVerbose
    			grabAttachments
    			grabComponents
				grabPriorities
    			grabProjectInfo
				grabProjectRoles
    			grabServerInfo
				grabStatuses    
				grabResolutions
    			grabVersions
    		) ] 
    );
}

END { }

=head1 EXPORT
A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.
=over 8
=item * new()
=item * grabVersions()
=item * grabStatuses()
=head1 SUBROUTINES/METHODS
=cut

use Carp;

use Data::Dumper; my $dd;

use File::Path qw(make_path remove_tree);
use LWP::UserAgent;
use HTTP::Headers;
use HTTP::Response;
use HTTP::Status qw(:constants :is status_message);
use JIRA::Client;


sub _connect {
	my ($self,@args) = @_;

   return($self->{client_handle})
}

sub _grab_list {
	my ($self,@args) = @_;
	my $ulist = [ ];
	return(\$ulist);	
}



=head2 new()
=over 8
=item :username
=item :password
=item :baseurl
=item :
=back
=cut

# Func: new(class_name [, options-hash] )
# Desc:
#
# Args: A hash containing key => value pairs to initialize the class.  The 
#       valid option keys are:
sub __new {
    my ($class,@args) = @_;
    my $self = {
         client_handle => undef		## #FIX Get rid of the leading colon on options
        ,':user_agent' => undef
        ,':max_results' => 13
        ,':max_issues' => undef
        ,':max_attachments' => undef
        ,':max_filesize' => undef
        ,':grab_thumbs' => 1
        ,'_server_info' => undef
        ,'_user_agent' => undef
        };
    foreach my $href (@args) {
    	@$self{ keys %{$href} } = values %{$href};
    }
    bless($self,$class);

    if ( (! $self->{client_handle}) && (! $self->{fileset}) ) {
        $self->{client_handle} = JIRA::Client->new(
             $self->{url}
        	,$self->{username}
        	,$self->{password}
        	);
    	$self->{'_server_info'} = eval { $self->{client_handle}->getServerInfo() };
    	croak sprintf("getServerInfo(): %s",$@) if $@;

    	if ($self->{debug} >= 1) { $dd = Data::Dumper->new([$self->{_server_info}]); print $dd->Dump(); }
    	if ($self->{verbose}) {
    		print("connected to: ".$self->{_server_info}->{baseUrl}." as '".$self->{username}."'\n");
    		print("server version: ".$self->{_server_info}->{version}.
    			" build: ".$self->{_server_info}->{buildNumber}."\n");
    	}
    }

	if ($self->{debug} >= 3) { $dd = Data::Dumper->new([$self]);  print $dd->Dump(); }
	return( $self->{client_handle} ? $self : undef);
}


=head2 appendToChain()
=cut

sub appendToChain {
	my ($self,$wand) = @_;
	croak "appendToChain(undef) failed, undef not a JWand\n" if (! $wand);
	if ($self->{_next_wand}) {
		print($self->{bname}," -> ") if ($self->{verbose});
		$self->{_next_wand}->appendToChain($wand);
	} else {
		print($self->{bname}," => ",$wand->{bname},"\n") if ($self->{verbose});
		$self->{_next_wand} = $wand;
	}
	
	if ($self->{debug} >= 3) { $dd = Data::Dumper->new([$self]);  print $dd->Dump(); }  
	return($self);
}

=head2 jira_handle()
=cut

sub jira_handle { 
	my $self = shift;
	return($self->{client_handle}); 
}

=head2 grabProjectKeys()
=cut

sub grabProjectKeys {
	my($self,$regx) = @_;
}

=head2 grabPriorities()
=cut

sub grabPriorities {
	my ($self,@args) = @_;
	my ($rslt,$ulist);
	
	$ulist = eval { $self->{client_handle}->getPriorities() };
	croak sprintf("getPriorities(): %s",$@) if $@;
	foreach my $key (@{$ulist}) { $key->{bname} = $self->{bname}; }
	if ($self->{debug} >= 1) { $dd = Data::Dumper->new([$ulist]);  print $dd->Dump(); }

	if ($self->{_next_wand}) {
		$rslt = $self->{_next_wand}->grabPriorities(@args);
		if ($self->{debug} >= 2) { $dd = Data::Dumper->new([$rslt]);  print $dd->Dump(); }
		$ulist = [ @{$ulist}, @{$rslt} ];
	}
	
	if ($self->{debug} >= 3) { $dd = Data::Dumper->new([$ulist]);  print $dd->Dump(); }
	return($ulist);
}

=head2 grabStatuses()
=cut

sub grabStatuses {
	my ($self,@args) = @_;
	my ($rslt,$ulist);
	
	$ulist = eval { $self->{client_handle}->getStatuses() };
	croak sprintf("getStatuses(): %s",$@) if $@;
	foreach my $key (@{$ulist}) { $key->{bname} = $self->{bname}; }
	if ($self->{debug} >= 1) { $dd = Data::Dumper->new([$ulist]);  print $dd->Dump(); }

	if ($self->{_next_wand}) {
		$rslt = $self->{_next_wand}->grabStatuses(@args);
		if ($self->{debug} >= 2) { $dd = Data::Dumper->new([$rslt]);  print $dd->Dump(); }
		$ulist = [ @{$ulist}, @{$rslt} ];
	}
	
	if ($self->{debug} >= 3) { $dd = Data::Dumper->new([$ulist]);  print $dd->Dump(); }
	return($ulist);
}

=head2 grabResolutions()
=cut

sub grabResolutions { 
	my ($self,@args) = @_;
	my ($rslt,$ulist);
	
	$ulist = eval { $self->{client_handle}->getResolutions() };
	croak sprintf("getResolutions(): %s",$@) if $@;
	foreach my $key (@{$ulist}) { $key->{bname} = $self->{bname}; }
	if ($self->{debug} >= 1) { $dd = Data::Dumper->new([$ulist]);  print $dd->Dump(); }

	if ($self->{_next_wand}) {
		$rslt = $self->{_next_wand}->grabResolutions(@args);
		if ($self->{debug} >= 2) { $dd = Data::Dumper->new([$rslt]);  print $dd->Dump(); }
		$ulist = [ @{$ulist}, @{$rslt} ];
	}
	
	if ($self->{debug} >= 3) { $dd = Data::Dumper->new([$ulist]);  print $dd->Dump(); }
	return($ulist);
}

=head2 grabProjectRoles()
=cut

sub grabProjectRoles {
	my ($self,@args) = @_;
	my ($rslt,$ulist);
	
	$ulist = eval { $self->{client_handle}->getProjectRoles() };
	croak sprintf("getProjectRoles(): %s",$@) if $@;
	foreach my $key (@{$ulist}) { $key->{bname} = $self->{bname}; }
	if ($self->{debug} >= 1) { $dd = Data::Dumper->new([$ulist]);  print $dd->Dump(); }

	if ($self->{_next_wand}) {
		$rslt = $self->{_next_wand}->grabProjectRoles(@args);
		if ($self->{debug} >= 2) { $dd = Data::Dumper->new([$rslt]);  print $dd->Dump(); }
		$ulist = [ @{$ulist}, @{$rslt} ];
	}
	
	if ($self->{debug} >= 3) { $dd = Data::Dumper->new([$ulist]);  print $dd->Dump(); }
	return($ulist);
}

=head2 grabComponents()
=cut
sub grabComponents { 
	my ($self,@args) = @_;
	my $ulist = [ ];
	
	foreach my $pkey (@args) {
		my $temp = eval { $self->{client_handle}->getComponents($pkey) };
		croak sprintf("getComponents(%s): %s",$pkey,$@) if $@;
		$ulist = [ @{$ulist}, @{$temp} ] if ($temp);
	}
	
	$dd = Data::Dumper->new([$ulist]);  print $dd->Dump();
	return(\$ulist);
}

=head2 grabVersions()
=cut

sub grabVersions { 
	my ($self,@args) = @_;
	my $ulist = [ ];
	
	foreach my $pkey (@args) {
		my $temp = eval { $self->{client_handle}->getVersions($pkey) };
		croak sprintf("getVersions(%s): %s",$pkey,$@) if $@;
		$ulist = [ @{$ulist}, @{$temp} ] if ($temp);
	}
	
	$dd = Data::Dumper->new([$ulist]);  print $dd->Dump();
	return(\$ulist);
}

=head2 grabProjectInfo()
=cut

sub grabProjectInfo { 
	my ($self,@args) = @_;
	my $ulist = [ ];
	
	foreach my $pkey (@args) {
		my $temp = eval { $self->{client_handle}->getProjectByKey($pkey) };
		croak sprintf("getProjectByKey(%s): %s",$pkey,$@) if $@;
		$ulist = [ @{$ulist}, [ $temp ] ] if ($temp);
	}
	
	$dd = Data::Dumper->new([$ulist]);  print $dd->Dump();
	return(\$ulist);
}

=head3 grabProjectRoleActors()
=cut

sub grabProjectRoleActors { 
	my ($self,$refpl,$refrl) = @_;
	my $ulist = [ ];

	$dd = Data::Dumper->new([$refpl]);  print $dd->Dump();
	$dd = Data::Dumper->new([$refrl]);  print $dd->Dump();
	
	foreach my $pkey (@{$refpl}) {
$dd = Data::Dumper->new([$pkey]);  print $dd->Dump();
		foreach my $rkey ($refrl) {
$dd = Data::Dumper->new([$rkey]);  print $dd->Dump();
			my $temp = eval { $self->{client_handle}->getProjectRoleActors($rkey->[0],$pkey) };
			$dd = Data::Dumper->new([$temp]);  print $dd->Dump();
			croak sprintf("getProjectRoleActors(%s,%s): %s",$rkey,$pkey,$@) if $@;
			$ulist = [ @{$ulist}, [ $temp ] ] if ($temp);
		}
	}
	
	$dd = Data::Dumper->new([$ulist]);  print $dd->Dump();
	return(\$ulist);
}

=over 4

=item B<grabAttachments> OUTPATH [, (<project-key>[,...])]]
asdfasdf

=back 

=cut

sub grabAttachments {
	my ($self,$path,@args) = @_;
	my ($cnt,$ua) = (undef,undef);
	
    ## Verify we are connected to a remote JIRA instance.

    return(undef) if (! $self->{client_handle});
	
	## If no project keys are specified find them all.
	
	## Make sure we have a UserAgent to access the remote JIRA instance to grab files.
	
	if (! $self->{'_user_agent'}) {
		$self->{':user_agent'} = $USER_AGENT if (! $self->{':user_agent'});
		my $rh = HTTP::Headers->new();
        $rh->authorization_basic($self->{':username'},$self->{':password'});
        $ua = $self->{'_user_agent'} = LWP::UserAgent->new( 
            agent => $USER_AGENT
            ,default_headers => $rh
            );
        ## $dd = Data::Dumper->new([$ua]); print $dd->Dump();
	}
   
	## Loop through the project keys grabbing all of the files on each iteration. 

    my $cnt_attach = 0;
    my $cnt_issues = 0;

    foreach my $pkey (@args) {

        my $ikey = "";            	
    	if ($pkey =~ m/(([A-Z]+)\-\d+)/) {
    		$pkey = $2;
    		$ikey = $1;
    	}

print "$pkey\n";
    	
        my $x = eval { $self->{client_handle}->getProjectByKey($pkey) };
        if ($@) {
        	carp sprintf("getProjectByKey('%s'): %s",$pkey,$@);
        	last;
        }
        
    	#### Iterate through each issue in the project.

        while (1) {
            my $jql = "project = $pkey " . (($ikey ne "") ? "and issueKey > $ikey " : "") . "order by issueKey asc";

#print "more issues....\n";

            my $ilist = eval { 
                $self->{client_handle}->getIssuesFromJqlSearch($jql,$self->{':max_results'}) 
                };
            if ($@) {
                carp sprintf("getIssuesFromJqlSearch('%s',%n): %s",$jql,$self->{':max_results'},$@);
                last;
            }
            last if (! @{$ilist});

            foreach my $issue (@$ilist) {
            	$cnt_issues++;
                $ikey = $issue->{'key'};
print "$ikey\n";                
                if (@{$issue->{'attachmentNames'}}) {
                    my $attach_list = eval { $self->{client_handle}->getAttachmentsFromIssue($ikey) };
                    croak sprintf("getAttachmentsFromIssue('%s'): %s",$ikey,$@) if $@;

                    ## $dd = Data::Dumper->new([$attach_list]); print $dd->Dump();
                        
                    my $fpth = "$path/$pkey/$ikey";
                    my $thmb = 0;
#print "$fpth\n";                    
                    foreach my $attach (@$attach_list) {

# Attachment Filespec := <jira-attachments>/<project-key>/<issue-key>/<attachment-id>
#            URL      := <base-url>/secure/attachment/<attachment-id>/<attachment-filename>
#                        https://request.siteworx.com/secure/attachment/17871/Wrong+FTP.jpg
#       '+' := <space_char>
# Thumbnail Filespec  := <jira-attachments>/<project-key>/<issue-key>/thumbs/_thumb_<attachment-id>.png
#           URL       := <base-url>/secure/thumbnail/<attachment-id>/_thumb_<attachment-id>.png
#                        https://request.siteworx.com/secure/thumbnail/17871/_thumb_17871.png
                    	
                    	next if (defined($self->{':max_filesize'}) && ($attach->{'filesize'} > $self->{':max_filesize'}));
                    	
                        my $furl = $self->{':url'}."/secure/attachment/".$attach->{'id'}."/".$attach->{'filename'};
                        my $fspc = $fpth."/".$attach->{'id'};
#print "$furl\n   ";
print "=> $fspc\n";
                                               
                    	make_path($fpth);
                        my $rh = $self->{'_user_agent'}->mirror($furl,$fspc);
                        $cnt_attach++ if (($rh->code() == HTTP_OK) || ($rh->code() == HTTP_NOT_MODIFIED));
                        
                        next if (! $self->{':grab_thumbs'});
                         
                        my $turl = $self->{':url'}."/secure/thumbnail/".$attach->{'id'}."/_thumb_".$attach->{'id'}.".png";
                        my $tspc = $fpth."/thumbs/_thumb_".$attach->{'id'}.".png";
#print "$turl\n   ";
print "=> $tspc\n";

                        make_path("$fpth/thumbs");
                        $rh = $self->{'_user_agent'}->mirror($turl,$tspc);
                        $thmb++ if (($rh->code() == HTTP_OK) || ($rh->code() == HTTP_NOT_MODIFIED));
                                            	
                        ## $dd = Data::Dumper->new([$attach]); print $dd->Dump();
                    }
                    remove_tree("$fpth/thumbs") if (! $thmb);
                    return($cnt_issues,$cnt_attach) if ((defined($self->{':max_attachments'}) &&
                                                         ($cnt_attach >= $self->{':max_attachments'})) ||
                                                        (defined($self->{':max_issues'}) &&
                                                         ($cnt_issues >= $self->{':max_issues'})));
                }
            }
        }
    }
    return($cnt_issues,$cnt_attach);
}



=head2 getDebug()
=cut
sub getDebug {
	my ($self,@args) = @_;
	carp "getDebug() is not implemented";
	return(undef);
}

=head2 getVerbose()
=cut
sub getVerbose {
	my ($self,@args) = @_;
	carp "getVerbose() is not implemented";
	return(undef);
}

=head2 setDebug()
=cut

sub setDebug {
	my ($self,@args) = @_;
	carp "setDebug() is not implemented";
	return(undef);
}

=head2 setVerbose()
=cut

sub setVerbose {
	my ($self,@args) = @_;
	carp "setVerbose() is not implemented";
	return(undef);
}

sub new {
	my ($class,@args) = @_;
	my $self = ( );
    foreach my $href (@args) {
    	@$self{ keys %{$href} } = values %{$href};
    }
    bless($self,$class);
	
	croak "error: configuration filename is missing" if (! $self->{filename});
	croak "error: configuration file '".$self->{filename}."' not found" if (! -f $self->{filename});
	if (! ($self->{config} = _get_configuration($self->{filename}))) {
		croak "error: configuration file contains errors";
	}
	return($self);
}


my %attribs = (
	 'id' 			=> [ 'integer', '' ]
	 ,'issue'		=> [ 'integer', 'as' ]
	 ,'author'		=> [ 'string', '' ]
	 ,'body'		=> [ 'text', '' ]
	 ,'created'		=> [ 'timestamp', '' ]
	 ,'updated' 	=> [ 'timestamp', 'asd' ]
	 ,'key'			=> [ 'string', 'asd' ]
	 ,'project'		=> [ 'string', 'asd' ]
	 ,'reporter'	=> [ 'string', 'asd' ]
	 ,'assignee'	=> [ 'string', 'asd' ]
	 ,'type'		=> [ 'integer', 'type' ]
	 ,'summary'		=> [ 'string', 'asd' ]
	 ,'priority'	=> [ 'integer', 'priorities' ]
	 ,'resolution'	=> [ 'integer', 'resolutions' ]
	 ,'status'		=> [ 'integer', 'statuses' ]
	 ,'votes'		=> [ 'integer', 0 ]
	 ,'watched'		=> [ 'integer', 0 ]
	 ,'workflowId'	=> [ 'integer', 'asd' ]
	 ,'security'	=> [ 'integer', 'asd' ]
	 ,'description'	=> [ 'text', 'asd' ]
);

my %entities = (
	 'WorkLog' 	=> [ 'id', 'issue', 'author', 'body', 'created', 'updated', 'startdate', 'timeworked' ]
	,'Issue' 	=> [ 'id', 'key', 'project', 'reporter', 'assignee', 'type', 'summary', 
	 				'priority', 'resolution', 'status', 'created', 'updated', 'votes', 'watched',
	 				'workflowId', 'security', 'description' ]
);

=head2 buildProjectImportFile
=cut

sub buildProjectImportFile {
	my ($self,@args) = @_;
    foreach my $href (@args) {
    	@$self{ keys %{$href} } = values %{$href};
    }

	

	return(undef);
}


1;	### End of 'JWand.pm'
__END__
### EOF

=head1 AUTHOR

Peter Shiner, C<< <pshiner at comskil.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-comskil-jwand at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Comskil-JWand>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Comskil::JWand


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Comskil-JWand>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Comskil-JWand>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Comskil-JWand>

=item * Search CPAN

L<http://search.cpan.org/dist/Comskil-JWand/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Peter Shiner.

This program is released under the following license: restrictive


=cut
