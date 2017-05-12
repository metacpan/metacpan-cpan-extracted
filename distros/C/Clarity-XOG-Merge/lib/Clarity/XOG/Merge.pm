package Clarity::XOG::Merge;

use 5.008;
use strict;
use warnings;

use File::Temp qw(tempfile tempdir);
use Data::Dumper;
use XML::Twig;
use Moose;

our $VERSION = '1.001';

has files           => ( is => "rw", isa => "ArrayRef", default => sub {[]}, auto_deref => 1 );
has projectids      => ( is => "rw", isa => "HashRef",  default => sub {{}} );
has finalprojectids => ( is => "rw", isa => "HashRef",  default => sub {{}} );
has buckets         => ( is => "rw" );
has cur_file        => ( is => "rw" );
has cur_proj        => ( is => "rw" );
has tmpdir          => ( is => "rw", default => sub { tempdir( CLEANUP => 1 ) });
has out_file        => ( is => "rw", default => "XOGMERGE.xml" );
has ALWAYSBUCKETS   => ( is => "rw", default => 1 );
has verbose         => ( is => "rw", default => 0 );
has debug           => ( is => "rw", default => 0 );
has force           => ( is => "rw", default => 0 );

sub TEMPLATE_HEADER {
        q#<!-- edited with Emacs 23 (http://emacswiki.org) by cris (na) -->
<!--XOG XML from CA is prj_projects_alloc_act_etc_read. Created by xogtool -->
<NikuDataBus xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="../xsd/nikuxog_project.xsd">
 <Header action="write" externalSource="NIKU" objectType="project" version="7.5.0" />
 <Projects>
#
}

sub TEMPLATE_FOOTER {
        q#
 </Projects>
</NikuDataBus>
#
}

sub cb_Collect_Project
{
        my ($t, $project) = @_;
        my $self = $t->{_self};

        my $projectID = $project->att('projectID');
        my $name      = $project->att('name');

        $self->projectids->{$projectID}{files}{$self->cur_file}++;
}

sub prepare {
        my ($self) = @_;
        # prepare temp dirs
        # open FINAL
}

sub finish
{
        my ($self) = @_;
        # close FINAL;
        # cleanup temp dirs
}

sub pass1_count
{
        my ($self) = @_;
        print "Pass 1: count\n" if $self->verbose;
        foreach my $f ($self->files) {
                print "  Read file $f\n" if $self->verbose;
                $self->cur_file( $f );
                my $twig= XML::Twig->new
                    ( twig_handlers =>
                      { 'Projects/Project' => \&cb_Collect_Project } );
                $twig->{_self} = $self;
                $twig->parsefile( $f );
        }
}

sub add_project_to_final
{
        my ($self, $project) = @_;
        # my $projectID = $project->att('projectID');
        # my $name      = $project->att('name');

        $project->set_pretty_print( 'indented');     # \n before tags not part of mixed content
        $project->print(\*XOGMERGEOUT);
}

sub add_project_to_bucket
{
        my ($self, $project) = @_;
        my $projectID  = $project->att('projectID');
        my $bucketfile = $self->tmpdir."/bucket-$projectID.tmp";

        open XOGMERGEBUCKET, ">>", $bucketfile or die "Cannot open bucket file ".$bucketfile.": $!";
        print XOGMERGEBUCKET "<Projects>\n" if not $self->buckets->{$bucketfile};
        $self->buckets->{$bucketfile}++;
        $project->print(\*XOGMERGEBUCKET);
        close XOGMERGEBUCKET;
}

sub prepare_output
{
        my ($self) = @_;

        my $answer = 'n';

        if (-e $self->out_file and not $self->force) {
                print "Output file '".$self->out_file."' exists. Overwrite (y/N)? ";
                read STDIN, $answer, 1;
                if ($answer !~ m/^y/i) {
                        print "Keep ".$self->out_file." and exit.\n" if $self->verbose;
                        exit 1;
                }
                print "Ok, overwrite ".$self->out_file.".\n" if $self->verbose;
        }
        open XOGMERGEOUT, ">", $self->out_file or die "Cannot open out file ".$self->out_file.": $!";
        print XOGMERGEOUT TEMPLATE_HEADER;
}

sub clean_old_buckets {
        my ($self) = @_;
        #system ("rm -f bucket-*.tmp");
        $self->buckets({});
}

sub finish_output
{
        my ($self) = @_;
        print XOGMERGEOUT TEMPLATE_FOOTER;
        close XOGMERGEOUT;
        print "Out file: ".$self->out_file."\n" if $self->verbose;
}

sub cb_Save_Project
{
        my ($t, $project) = @_;
        my $self = $t->{_self};

        my $projectID = $project->att('projectID');
        my $name      = $project->att('name');

        if ($self->ALWAYSBUCKETS or keys %{$self->projectids->{$projectID}{files}} > 1)
        {
                # do this always (without surrounding if/else
                # if single-org-projects rarely occur
                $self->add_project_to_bucket($project);
        }
        else
        {
                $self->add_project_to_final($project);
        }
}

sub cb_Open_Project
{
        my ($t, $project) = @_;
        my $self = $t->{_self};

        # debug
        my $projectID = $project->att('projectID');
        my $name      = $project->att('name');

        $self->cur_proj( $project ) unless $self->cur_proj;
}

sub cb_Save_Resource
{
        my ($t, $resource) = @_;
        my $self = $t->{_self};

        my $resourceID = $resource->att('resourceID');

        my $resources = $self->cur_proj->first_child('Resources');
        my $res = $resource->cut;
        $res->paste(last_child => $resources); # ok
}

sub add_buckets_to_final
{
        my ($self) = @_;
        foreach my $bucket (keys %{$self->buckets})
        {
                $self->cur_file( $bucket );
                $self->cur_proj( undef );
                my $twig= XML::Twig->new (
                                          start_tag_handlers => { "Project"  => \&cb_Open_Project },
                                          twig_handlers      => { "Resource" => \&cb_Save_Resource },
                                         );
                $twig->{_self} = $self;
                $twig->parsefile( $bucket );
                $self->add_project_to_final($self->cur_proj); # wrong duplicate
        }
}

sub close_buckets_xml {
        my ($self) = @_;
        foreach my $bucketfile (keys %{$self->buckets}) {
                open XOGMERGEBUCKET, ">>", $bucketfile or die "Cannot open bucket file ".$bucketfile.": $!";
                print XOGMERGEBUCKET "</Projects>\n";
                close XOGMERGEBUCKET;
        }
}

sub collect_projects_to_buckets_or_final
{
        my ($self) = @_;
        foreach my $f ($self->files)
        {
                print "  Read file $f\n" if $self->verbose;
                $self->cur_file( $f );
                my $twig= XML::Twig->new (twig_handlers => { 'Projects/Project' => \&cb_Save_Project });
                $twig->{_self} = $self;
                $twig->parsefile( $f );
        }
        $self->close_buckets_xml;
}

sub pass2_merge
{
        my ($self) = @_;
        print "Pass 2: merge\n" if $self->verbose;
        $self->prepare_output;
        $self->clean_old_buckets;
        $self->collect_projects_to_buckets_or_final;
        $self->add_buckets_to_final;
        $self->finish_output;
}

sub cb_Count_Project {
        my ($t, $project) = @_;
        my $self = $t->{_self};

        my $projectID = $project->att('projectID');
        my $name      = $project->att('name');

        $self->finalprojectids->{$projectID}++;
}

sub pass3_validate {
        my ($self) = @_;

        print "Pass 3: validate\n" if $self->verbose;
        print "  File ".$self->out_file."\n" if $self->verbose;
        my $twig= XML::Twig->new (twig_handlers => { 'Projects/Project' => \&cb_Count_Project });
        $twig->{_self} = $self;
        $twig->parsefile( $self->out_file );

        my $projectcount_in  = scalar keys %{$self->projectids};
        my $projectcount_out = scalar keys %{$self->finalprojectids};
        if ($projectcount_in == $projectcount_out) {
                print "  OK - project count ($projectcount_in/$projectcount_out)\n" if $self->verbose;
        } else {
                print "  NOT OK - project count ($projectcount_in/$projectcount_out)\n" if $self->verbose;
        }

        foreach (keys %{$self->projectids}) {
                if (exists $self->projectids->{$_}) {
                        print "  OK - project $_\n" if $self->verbose;
                } else {
                        print "  NOT OK - project $_\n" if $self->verbose;
                        exit 2;
                }
        }

}

sub Main
{
        my ($self) = @_;
        $self->prepare;
        $self->pass1_count;
        $self->pass2_merge;
        $self->pass3_validate;
        $self->finish();
}

1; # End of Clarity::XOG::Merge

__END__

=pod

=head1 NAME

Clarity::XOG::Merge - Merge several Clarity XML Open Gateway (XOG) files

=head1 SYNOPSIS

Merge several Clarity XOG ("XML Open Gateway") files into one

    use Clarity::XOG::Merge;
    my $merger = Clarity::XOG::Merge->new
                 ( files    => ['t/QA.xml', 't/PS.xml', 't/TJ.xml'],
                   out_file => $out_file );
    $merger->Main;

Or using the frontend tool:

    xogtool merge -i subdir_with_inputfiles -o MERGEDRESULT.xml

=head1 ABOUT

I<Clarity>(R) is a project and resource management software from
I<Computer Associates International, Inc.>(R), see
L<http://de.wikipedia.org/wiki/Clarity>.

It provides data import of so called "XOG" ("XML Open Gateway") files,
sometimes historically called "nikureport". Such files are generated
for instance by TaskJuggler, see
L<http://www.taskjuggler.org/tj3/manual/nikureport.html>.

Sometimes, e.g., when different departments of one company use their
own project management software, respectively, such XOG files need to
be merged into one before being imported into the central Clarity
database.

This module L<Clarity::XOG::Merge|Clarity::XOG::Merge> and its
frontend tool B<xogtool>) provide that merging.

It is implemented carefully to handle very large files without
suffering from memory issues (by using L<XML::Twig|XML::Twig>, temp
files and doing several passes). So the only restrictions should be the
supported max-file-size of your filesystem. (However, please note that
importing a large merged XOG file into Clarity can have its own memory
issues, due to their import probably being XML-DOM based.)

It is also explicitely polished to work under Windows using
L<Strawberry Perl|http://strawberryperl.com/> and being packaged into
a single standalone C<xogtool.exe> using
L<PAR|http://search.cpan.org/dist/PAR> (tested with Strawberry Perl
5.8 on Windows XP). A corresponding C<mkexe.bat> file to call the PAR
packager is provided.

=head1 AUTHOR

Steffen Schwigon, C<< <ss5 at renormalist.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-clarity-xog-merge
at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Clarity-XOG-Merge>. I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2010-2011 Steffen Schwigon, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
