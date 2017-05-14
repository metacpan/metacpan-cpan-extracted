package API::ReviewBoard;

use strict;
use warnings;
use LWP;
use HTTP::Cookies;
use Carp qw(croak);
use Params::Validate qw[validate OBJECT SCALAR ARRAYREF];
use Data::Dumper;
use vars qw( @EXPORT @ISA );


=head1 NAME

API::ReviewBoard - ReviewBoard Class to work with exported ReviewBoard 2.0 APIs.

=head1 SYNOPSIS
use strict;
use warnings;
use Data::Dumper;

#Imports ReviewBoard Class.
use API::ReviewBoard;


#Init's the ReviewBoard Class.
my $rb = ReviewBoard->new(  hostedurl => 'http://hostedurl.reviewboard.com',
                            username => 'user',
                            password => 'password' );


print "*****************************************************\n";
print "   UnitTest to exercise ReviewBoard Class API's     \n";
print "   Author: chetang\@cpan.org                        \n"; 
print "*****************************************************\n\n";

my $submitter = $rb->getSubmitter(changenum => '13638134');
print "Review Submitted by:\n", @$submitter, "\n\n";

my $reviewlink = $rb->getReviewBoardLink(changenum => '13027232');
print "Review Board Link:\n",$reviewlink,"\n\n";

my $description = $rb->getReviewDescription(changenum => '13027232');
print "Review Request description:\n",$description,"\n\n";

my $date_added = $rb->getReviewDateAdded(changenum  => '13027322');
print "Review Request Added Date:\n", $date_added, "\n\n";

my $last_updated = $rb->getReviewLastUpdated(changenum  => '13027232');
print "Review Request Last Updated Date:\n", $last_updated, "\n\n";

my $reviewers = $rb->getReviewers(changenum => '1302722');
print "Reviewers assigned to Review Request:\n @$reviewers \n\n";

my $summary = $rb->getSummary(changenum => '1302722');
print "Summary of Review Request:\n", $summary, "\n\n";

my $bug = $rb->getBugIds(changenum => '1302722');
print "Associated Bug list:\n", $bug, "\n\n";

my $commentscount = $rb->getReviewCommentsCount( reviewnum => '4108034');
print "No of comments added for Review Request:\n", $commentscount, "\n\n";

my $outgoingreviews = $rb->getOutgoingReviewsCount(user => 'users');
print "No of outgoing Review Requests by user 'users':\n",$outgoingreviews,"\n\n";

my $reviewsbydate = $rb->getOutgoingReviewsCountByDate(user => 'users', startdate => '2011-03-01', enddate => '2011-03-30');
print "No of outgoing Review Requests by user 'users' during time interval:\n", $reviewsbydate, "\n\n";

my $reviewsbystatus = $rb->getOutgoingReviewsCountByStatus(user => 'users', status => 'submitted');
print "No of outgoing Review Requests by user 'users' in state submitted:\n", $reviewsbystatus, "\n\n";

my $incomingreviews = $rb->getIncomingReviewsCount(user => 'users');
print "No of incoming review requests made to user:\n", $incomingreviews, "\n\n";

=head1 DESCRIPTION

C<API::ReviewBoard> provides an interface to work with the exported ReviewBoard 2.0 APIs.

You can choose to either subclass this module, and thus using its
accessors on your own module, or to store an C<API::ReviewBoard>
object inside your own object, and access the accessors from there.
See the C<SYNOPSIS> for examples.

=head1 METHODS

=head2 my $rb = API::ReviewBoard->new(  hostedurl => 'http://reviewboard.company.com', 
                username => 'user', 
                password => 'passwd' );
Creates a new API::ReviewBoard object. 
=cut

sub new {
	my $class = shift;
	my %args = @_;
	my $self;
	%args  = validate(
        @_,
          {  
		hostedurl  => { type => SCALAR, optional => 0 },
		username  => { type => SCALAR, optional => 0 },
		password  => { type => SCALAR, optional => 0 },
	  }
	);

        $self->{_owner} = $$;
        $self->{_hostedurl} = $args{hostedurl};
	$self->{_username} = $args{username};
	$self->{_password} = $args{password};

        $self->{_useragent} = LWP::UserAgent->new;
        $self->{_cookie_jar} = HTTP::Cookies->new(file => "lwpcookies.txt", autosave => 1);

        # post request to login
        my $link = $self->{_hostedurl}.'api/json/accounts/login/';
        my $request = new HTTP::Request('POST',$link);

        my $content = 'username='.$self->{_username}.'&password='.$self->{_password};
        $request->content($content);
        my $response = $self->{_useragent}->simple_request($request);

        # extract cookie from response header
        $self->{_cookie_jar}->extract_cookies($response);


        bless $self,$class;
        return $self;

}

=head2 $rb->getReviewBoardLink(changenum  => '112345');
Gets the review board link for a ACTIVE change request number.
=cut

sub getReviewBoardLink {
	my $self = shift;
	my %args  = validate(
		@_,
		{  changenum  => { type => SCALAR, optional => 0 },
		}
	);
	$self->{_changenum} = $args{changenum};
        
	# get request to get review number based on change number
	my $changenumlink =  $self->{_hostedurl}.'/api/review-requests/?changenum='.$self->{_changenum};
	my $request = new HTTP::Request('GET', $changenumlink);
        $self->{_cookie_jar}->add_cookie_header($request);
        my $response = $self->{_useragent}->simple_request($request);
        my $xml = $response->as_string;
        
        $xml=~ m/.*"id": (\d+),.*/;
        my $reviewnum = $1;
        
        my $reviewlink =  $self->{_hostedurl}.'/r/'.$reviewnum;

        return $reviewlink;
}


=head2 $rb->getReviewDescription(changenum  => '112345');
The new review request description from ACTIVE change request.
=cut

sub getReviewDescription {
        my $self = shift;
        my %args  = validate(
                @_,
                {  changenum  => { type => SCALAR, optional => 0 },
                }
        );
        $self->{_changenum} = $args{changenum};


        # get request to get review number based on change number
        my $changenumlink =  $self->{_hostedurl}.'/api/review-requests/?changenum='.$self->{_changenum};
        my $request = new HTTP::Request('GET', $changenumlink);
        $self->{_cookie_jar}->add_cookie_header($request);
        my $response = $self->{_useragent}->simple_request($request);
        my $xml = $response->as_string;

        $xml =~ m/.*"description": "(.*)", "links".*/;
        my $description = $1;
        $description =~ s/(\\n)+/\n/g;

	return ($description);        
}

=head2 $rb->getReviewDateAdded(changenum  => '112345');

Gets the date on which ACTIVE change request was added.
=cut

sub getReviewDateAdded {
        my $self = shift;
        my %args  = validate(
                @_,
                {  changenum  => { type => SCALAR, optional => 0 },
                }
        );
        $self->{_changenum} = $args{changenum};

        my $changenumlink =  $self->{_hostedurl}.'/api/review-requests/?changenum='.$self->{_changenum};
        my $request = new HTTP::Request('GET', $changenumlink);
        $self->{_cookie_jar}->add_cookie_header($request);
        my $response = $self->{_useragent}->simple_request($request);
        my $xml = $response->as_string;

        $xml =~ m/.*"time_added": "(.*)", "summary".*/;
        my $dateadded = $1;

	return ($dateadded);
}



=head2 $rb->getReviewLastUpdated(changenum  => '112345');
Gets the date on which change request was last updated.
=cut

sub getReviewLastUpdated {
        my $self = shift;
        my %args  = validate(
                @_,
                {  changenum  => { type => SCALAR, optional => 0 },
                }
        );
        $self->{_changenum} = $args{changenum};
        
	my $changenumlink =  $self->{_hostedurl}.'/api/review-requests/?changenum='.$self->{_changenum};
        my $request = new HTTP::Request('GET', $changenumlink);
        $self->{_cookie_jar}->add_cookie_header($request);
        my $response = $self->{_useragent}->simple_request($request);
        my $xml = $response->as_string;

        $xml =~ /.*"last_updated": "(.*)", "description".*/;
        my $lastupdated = $1;


        return ($lastupdated);
}


=head2 $rb->getReviewers(changenum  => '112345');

Gets the name of the reviewers assigned for ACTIVE change request number.
The function returns an ARRAYREF to the user.

=cut

sub getReviewers {
        my $self = shift;
        my %args  = validate(
                @_,
                {  changenum  => { type => SCALAR, optional => 0 },
                }
        );
        $self->{_changenum} = $args{changenum};

        my $userlink = $self->{_hostedurl}.'/api/review-requests/?changenum='.$self->{_changenum};
        my $request = new HTTP::Request('GET', $userlink);
        $self->{_cookie_jar}->add_cookie_header($request);
        my $response = $self->{_useragent}->simple_request($request);
        my $xml = $response->as_string;

    $xml =~ m/.*"target_people": (.*), "testing_done".*/;
    my $name = $1;
    my @arr;
    my $count = @arr = $name =~ /"title": "(\w+)"/g;
    
    my $reviewers = \@arr;
    
    return ($reviewers);

}


=head2 $rb->getSubmitter(changenum  => '112345');

Gets the name of the submitter who submitted the ACTIVE change request.

=cut

sub getSubmitter {
        my $self = shift;
        my %args  = validate(
                @_,
                {  changenum  => { type => SCALAR, optional => 0 },
                }
        );
        $self->{_changenum} = $args{changenum};

        my $userlink = $self->{_hostedurl}.'/api/review-requests/?changenum='.$self->{_changenum};
        my $request = new HTTP::Request('GET', $userlink);
        $self->{_cookie_jar}->add_cookie_header($request);

        my $response = $self->{_useragent}->simple_request($request);
        my $xml = $response->as_string;

        $xml =~ m/.*"submitter": (.*), "screenshots".*/;
        my $name = $1;
        my @arr;
        my $count = @arr = $name =~ /"title": "(\w+)"/g;

        my $submitter = \@arr;

        return ($submitter);

}


=head2 $rb->getSummary(changenum  => '112345');

The review request's brief summary of ACTIVE change request.

=cut

sub getSummary {
        my $self = shift;
        my %args  = validate(
                @_,
                {  changenum  => { type => SCALAR, optional => 0 },
                }
        );
        $self->{_changenum} = $args{changenum};

        my $userlink = $self->{_hostedurl}.'/api/review-requests/?changenum='.$self->{_changenum};
        my $request = new HTTP::Request('GET', $userlink);
        $self->{_cookie_jar}->add_cookie_header($request);

        my $response = $self->{_useragent}->simple_request($request);
        my $xml = $response->as_string;

        $xml =~ m/.*"summary": "(.*)", "public".*/;
        my $summary = $1;


        return ($summary);
}


=head2 $rb->getSummary(changenum  => '112345');

Get the list of bugs closed or referenced by the ACTIVE change request.

=cut

sub getBugIds {
        my $self = shift;
        my %args  = validate(
                @_,
                {  changenum  => { type => SCALAR, optional => 0 },
                }
        );
        $self->{_changenum} = $args{changenum};

        my $userlink = $self->{_hostedurl}.'/api/review-requests/?changenum='.$self->{_changenum};
        my $request = new HTTP::Request('GET', $userlink);
        $self->{_cookie_jar}->add_cookie_header($request);
        my $response = $self->{_useragent}->simple_request($request);
        my $xml = $response->as_string;

        $xml =~ m/.*"bugs_closed": (.*), "changenum".*/;
        my $bugids = $1;
        return ($bugids);
}


=head2 $rb->getReviewCommentsCount(reviewnum  => '41080');
Gets the count of comments received for an ACTIVE change request.
=cut


sub getReviewCommentsCount {
        my $self = shift;
        my %args  = validate(
                @_,
                {  reviewnum  => { type => SCALAR, optional => 0 },
                }
        );
        $self->{_reviewnum} = $args{reviewnum};

	my $userlink = $self->{_hostedurl}.'/api/review-requests/'.$self->{_reviewnum}.'/reviews/?counts-only=1';
	my $request = new HTTP::Request('GET', $userlink);
	$self->{_cookie_jar}->add_cookie_header($request);
        my $response = $self->{_useragent}->simple_request($request);
        my $xml = $response->as_string;

	$xml =~ m/.*{"count": (\d+).*/ ;
	my $count = $1;
	return $count;
	
}


=head2 $rb->getOutgoingReviewsCount(user  => 'abdcde');
Gets the count of review requests made by a user.
=cut

sub getOutgoingReviewsCount {
        my $self = shift;
        my %args  = validate(
                @_,
                {  user  => { type => SCALAR, optional => 0 },
                }
        );
        $self->{_user} = $args{user};

        my $userlink = $self->{_hostedurl}.'/api/review-requests/?from-user='.$self->{_user}.'&status=all&counts-only=1';
        my $request = new HTTP::Request('GET', $userlink);
        $self->{_cookie_jar}->add_cookie_header($request);
        my $response = $self->{_useragent}->simple_request($request);
        my $xml = $response->as_string;

        $xml =~ m/.*{"count": (\d+).*/ ;
        my $count = $1;
        return ($count);

}


=head2 $rb->getOutgoingReviewsCountByDate(user  => 'abdcde', startdate => '2011-03-01',
                   enddate => '2011-03-30');

Gets the count of review requests made by a user during time interval.

=cut

sub getOutgoingReviewsCountByDate {
        my $self = shift;
        my %args  = validate(
                @_,
                {  user  => { type => SCALAR, optional => 0 },
		   startdate => { type => SCALAR, optional => 0 },
		   enddate => { type => SCALAR, optional => 0 },
                }
        );

        $self->{_user} = $args{user};
	$self->{_startdate} = $args{startdate};
	$self->{_enddate} = $args{enddate};

        my $userlink = $self->{_hostedurl}.'/api/review-requests/?from-user='.$self->{_user}.'&time-added-from='.$self->{_startdate}.'&time-added-to='.$self->{_enddate}.'&status=all&counts-only=1';
        my $request = new HTTP::Request('GET', $userlink);
        $self->{_cookie_jar}->add_cookie_header($request);
        my $response = $self->{_useragent}->simple_request($request);
        my $xml = $response->as_string;

        $xml =~ m/.*{"count": (\d+).*/ ;
        my $count = $1;
        return $count;

}



=head2 $rb->getOutgoingReviewsCountByStatus(user  => 'abdcde', status => 'all | pending |submitted | discarded' );

Gets the count of review requests made by a user with status in [all | pending |submitted | discarded].

=cut

sub getOutgoingReviewsCountByStatus {
        my $self = shift;
        my %args  = validate(
                @_,
                {  user  => { type => SCALAR, optional => 0 },
                   status => { type => SCALAR, optional => 0 },
                }
        );

    $self->{_user} = $args{user};
    $self->{_status} = $args{status};
    
        my $userlink = $self->{_hostedurl}.'/api/review-requests/?from-user='.$self->{_user}.'&status='.$self->{_status}.'&counts-only=1';
        my $request = new HTTP::Request('GET', $userlink);
        $self->{_cookie_jar}->add_cookie_header($request);
        my $response = $self->{_useragent}->simple_request($request);
        my $xml = $response->as_string;

        $xml =~ m/.*{"count": (\d+).*/ ;
        my $count = $1;
        return $count;

}

=head2 $rb->getIncomingReviewsCount(user  => 'abdcde');

Gets the count of review requests made to a user.

=cut

sub getIncomingReviewsCount {
        my $self = shift;
        my %args  = validate(
                @_,
                {  user  => { type => SCALAR, optional => 0 },
                }
        );
        $self->{_user} = $args{user};

        my $userlink = $self->{_hostedurl}.'/api/review-requests/?to-users='.$self->{_user}.'&counts-only=1';
        my $request = new HTTP::Request('GET', $userlink);
        $self->{_cookie_jar}->add_cookie_header($request);
        my $response = $self->{_useragent}->simple_request($request);
        my $xml = $response->as_string;

        $xml =~ m/.*{"count": (\d+).*/ ;
        my $count = $1;
        return $count;
}

=head1 AUTHOR

This module by Chetan Giridhar E<lt>chetang@cpan.orgE<gt>.

=head1 COPYRIGHT

This library is free software; you may redistribute and/or modify it
under the same terms as Perl itself.

=cut

1;
