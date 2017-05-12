package App::SFDC::Command::Deploy;
# ABSTRACT: Deploy files to SFDC

use strict;
use warnings;

our $VERSION = '0.21'; # VERSION

use Data::Dumper;
use File::Find 'find';
use Log::Log4perl ':easy';

use WWW::SFDC::Manifest;
use WWW::SFDC::Zip;

use Moo;
use MooX::Options;
with 'App::SFDC::Role::Logging',
    'App::SFDC::Role::Credentials';


option 'all',
    doc => 'Deploy all files in the src/ directory.',
    is => 'ro',
    short => 'a';


option 'deletions',
    doc => 'Whether or not to deploy deletions.',
    is => 'ro',
    default => 1,
    negativable => 1;


option 'files',
    doc => 'Files to deploy. Defaults to a list read from STDIN, unless all is set.',
    format => 's',
    is => 'ro',
    lazy => 1,
    repeatable => 1,
    short => 'f',
    default => sub {
        my $self = shift;
        my @filelist;
        if ($self->all) {
          find(
                sub {
                    push @filelist, $File::Find::name
                        unless (-d or /(package\.xml|destructiveChanges(Pre|Post)?\.xml|\.bak)/)
                },
                'src'
            );
        } else {
            INFO 'Reading files from STDIN';
            @filelist = <STDIN>;
            chomp @filelist;
            @filelist = grep {$_} @filelist;
        }
        DEBUG "File list for deployment: ". Dumper(\@filelist);
        return \@filelist;
    };


option 'rollback',
    is => 'ro',
    default => 1,
    negativable => 1;


option 'runtests',
    doc => 'Defaults to off, turn on by setting to 1',
    short => 't',
    is => 'ro',
    default => 0;


option 'testoutput',
    format => 's',
    short => 'o',
    is => 'ro';


option 'validate',
    is => 'ro',
    short => 'v',
    default => 0;


option 'zipfile',
    is => 'ro',
    short => 'z',
    isa => sub {
        LOGDIE "The specified zipfile, $_[0], doesn't exist!" unless -e $_[0];
    };

has '_zipFile',
    lazy => 1,
    is => 'rw',
    default => sub {
        my $self = shift;

        return $self->zipfile
            ? do {
                open my $FH, '<', $self->zipfile;
                binmode $FH;
                local $/;
                <$FH>;
            }
            : WWW::SFDC::Zip::makezip(
                'src/',
                $self->_manifest->getFileList,
                'package.xml',
                (
                    $self->deletions
                      ? ('destructiveChangesPre.xml', 'destructiveChangesPost.xml')
                      : ()
                )
            );
    };

has '_manifest',
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        WWW::SFDC::Manifest->new(
            constants => $self->_session->Constants,
            apiVersion => $self->_session->apiVersion,
        )->addList(@{$self->files})->writeToFile('src/package.xml');
    };

has '_result',
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        $self->_session->Metadata->deployMetadata(
            $self->_zipFile,
            {
                singlePackage => 'true',
                ($self->rollback ? (rollbackOnError => 'true') : ()),
                ($self->validate ? (checkOnly => 'true') : ()),
                ($self->runtests ? (testLevel => 'RunLocalTests') : ()),
            }
        );
    };

sub _JUnitOutput {
    my $self = shift;

    return unless $self->testoutput and ($self->_result->result->{runTestsEnabled} eq 'true');
    Role::Tiny->apply_roles_to_object(
        $self->_result,
        'App::SFDC::Role::DeployResult::JUnitOutput'
    );
    $self->_result->printToJUnit($self->testoutput);
}


sub execute {
    my $self = shift;
    unless (scalar @{$self->files} or $self->zipfile) {
        INFO "Nothing to deploy; exiting";
        return 1; # truthy
    }
    print $self->_result;
    $self->_JUnitOutput;
    return $self->_result->success;
}

1;

__END__

=pod

=head1 NAME

App::SFDC::Command::Deploy - Deploy files to SFDC

=head1 VERSION

version 0.21

=head1 OPTIONS

=head2 --all -a

Deploy all files in the src/ directory.

=head2 --deletions --no-deletions

Whether or not to deploy deletions. By default, Deploy includes any of the
following, if they're present:

    destructiveChanges.xml
    destructiveChangesPre.xml
    destructiveChangesPost.xml

=head2 --files -f

Files to deploy. Defaults to a list read from STDIN, unless all is set.

You can use various calling style, for instance:

    -f "src/profiles/blah.profile" --file "src/classes/blah.cls,src/classes/foo.cls"

=head2 --rollback --no-rollback

Whether or not to send the 'rollbackonerror' header. Defaults to true.

=head2 --runtests -t

If set, set 'testLevel' to 'RunLocalTests', i.e. run all tests in your own
namespace. This has no effect on Production, and doesn't work before API v34.0

=head2 --testoutput -o

If set, then this file will be populated with JUnit-formatted xml containing
the test results of this deployment.

=head2 --validate -v

If set, set 'isCheckOnly' to true, i.e. perform a validation deployment.

=head2 --zipfile -z

If set, deploy this zip file, rather than building one from scratch.

=head1 METHODS

=head2 execute()

builds a zip file and deploys it to Salesforce.com.

=head1 AUTHOR

Alexander Brett <alexander.brett@sophos.com> L<http://alexander-brett.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Sophos Limited L<https://www.sophos.com/>.

This is free software, licensed under:

  The MIT (X11) License

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
