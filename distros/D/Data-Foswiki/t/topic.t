#!perl -T

use strict;
use Test::More tests => 9;

#test only importing deserialise - make the other full
use Data::Foswiki qw(deserialise);

my $topic;
$topic = deserialise();
ok( !defined($topic), 'no parameters' );

$topic = deserialise();
ok( !defined($topic), 'empty string' );
ok(
    defined(
        Data::Foswiki::deserialise(
'%META:TOPICINFO{author="ProjectContributor" date="1282135389" format="1.1" version="1"}%'
        )
    ),
    'just TOPICINFO'
);

$topic = Data::Foswiki::deserialise("one\ntwo");
ok( $topic->{TEXT} eq "one\ntwo", 'test linefeed combination' );
$topic = Data::Foswiki::deserialise( "one", "two" );
ok( $topic->{TEXT} eq "one\ntwo", 'test linefeed combination' );

#my $tt = Data::Foswiki::deserialise("one\ntwo");
#use Data::Dumper; print STDERR Dumper($tt);

$topic = deserialise(<DATA>);

ok( $topic->{TOPICINFO}{author} eq 'ProjectContributor', 'loaded TOPICINFO' );
ok( $topic->{TOPICMOVED}{from}  eq 'SimultaneousEdits',  'loaded TOPICMOVED' );
ok( $topic->{FIELD}{RelatedTopics}{value} eq 'UserDocumentationCategory',
    'loaded FIELDS' );

my $string = Data::Foswiki::serialise($topic);
ok( length($string) > 10, 'string contains something' );

#print STDERR "\n====\n$string\n====\n";
#ok($string eq join('', <DATA>), 'what comes out, must be what goes in');

#TODO: can't compare serialised string to original, as i'm not preserving attr order in META

1;
__END__
%META:TOPICINFO{author="ProjectContributor" date="1282135389" format="1.1" version="1"}%
%META:TOPICPARENT{name="FrequentlyAskedQuestions"}%
Foswiki allows multiple simultaneous edits of the same topic, and then merges the different changes automatically. You probably won't even notice this happening unless there is a conflict that cannot be merged automatically. In this case, you may see Foswiki inserting "change marks" into the text to highlight conflicts between your edits and another person's. 
These change marks are only used if you edit the same part of a topic as someone else, and they indicate what the text used to look like, what the other person's edits were, and what your edits were.

Foswiki will warn if you attempt to edit a topic that someone else is editing. It will also warn if a merge was required during a save.

%META:FORM{name="FAQForm"}%
%META:TOPICMOVED{by="ProjectContributor" date="1280839581" from="SimultaneousEdits" to="FaqSimultaneousEdits"}%
%META:FIELD{name="TopicTitle" attributes="H" title="<nop>TopicTitle" value="How simultaneous edits are handled in Foswiki"}%
%META:FIELD{name="TopicClassification" attributes="" title="TopicClassification" value="FrequentlyAskedQuestion"}%
%META:FIELD{name="TopicSummary" attributes="" title="Topic Summary" value="What happens if two or more users try to edit the same topic simultaneously?"}%
%META:FIELD{name="InterestedParties" attributes="" title="Interested Parties" value=""}%
%META:FIELD{name="RelatedTopics" attributes="" title="Related Topics" value="UserDocumentationCategory"}%
