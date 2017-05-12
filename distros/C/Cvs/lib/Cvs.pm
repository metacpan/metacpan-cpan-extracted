package Cvs;

use strict;
use Carp;
use Cwd;
use FileHandle;
use File::Path qw(rmtree);
use Cvs::Cvsroot;
use base qw(Class::Accessor);
use vars qw($AUTOLOAD %LOADED);

$Cvs::VERSION = 0.07;

Cvs->mk_accessors(qw(debug pwd workdir));

=pod

=head1 NAME

Cvs - Object oriented interface to the CVS command

=head1 SYNOPSIS

    use Cvs;

    my $cvs = new Cvs
      (
        '/path/to/repository/for/module',
        cvsroot => ':pserver:user@host:/path/to/cvs',
        password => 'secret'
      ) or die $Cvs::ERROR;

    $cvs->checkout('module');

    ...

    my $status = $cvs->status('file');
    if($status->is_modified)
    {
        $cvs->commit('file');
    }

    $cvs->release({delete_after => 1});
    $cvs->logout();

=head1 DESCRIPTION

bla bla

=head1 LEGACY CVS METHODS

=head2 new

    Cvs = new Cvs ["workdir"] [key => "value" [, ...]];

    my $obj = new Cvs "workdir";

    my $obj = new Cvs "workdir", cvsroot => "/path/to/cvsroot";

    my $obj = new Cvs cvsroot => ":pserver:user\@host:/path/to/cvs";

Create a new Cvs object for the repository given in argument. Note
that the working directory doesn't need to already exist.

Allowed parameters are:

=over 4

=item workdir

Path to the working directory. You don't need it if you plan to use
only remote commands like rdiff or rtag.

=item cvsroot

Address of the cvsroot. See the Cvs::Cvsroot module documentation for
more information on supported CVSROOT. Note that if you don't supply a
cvs root but a working directory, Cvs will try to guess the CVSROOT
value. You still need to supply password and others authentication
values. If Cvs can't determine the CVSROOT value, an error will be
thrown and the object will not be created.

=item password, passphrase, ...

All options supported by Cvs::Cvsroot are supported here. Please see
Cvs::Cvsroot documentation for more details.

=back

=head2 checkout

    Cvs::Result::Checkout = $obj->checkout("module", {key => "value"});

Checkout the module "module" in the repository (the one that served to
create the Cvs object) from the cvsroot given in parameter.

Allowed parameters are:

=over 4

=item reset

Boolean value used to reset any sticky tags, dates or options (See the
-A cvs checkout option).

=item revision

Specify the revision to checkout the module (See the -r cvs checkout
option).

=item date

Specify the date from when to checkout the module (See the -D cvs
checkout option).

=back

L<Cvs::Result::Checkout>.

=head2 update

    Cvs::Result::Update = $cvs->update();

L<Cvs::Result::Update>.

=head2 status

    Cvs::Result::StatusItem = $cvs->status("file");

    Cvs::Result::StatusList =
        $cvs->status("file1", "file2", {multiple => 1});

Get the status of one of more files.

Allowed parameters are:

=over 4

=item multiple

Boolean value that specify the type of object returned. If true, a
Cvs::Result::StatusList object is returned, and status on more than
one files can be handled. If false, a Cvs::Result::StatusItem object
is return and only one file status can be handled (the first one if
several).

=item recursive

If a directory is supplied, process it recursively (Default true).

=back

L<Cvs::Result::StatusItem>, L<Cvs::Result::StatusList>

=head2 diff

    Cvs::Result::DiffItem = $cvs->diff();

    Cvs::Result::DiffList = $cvs->diff({multiple => 1});

L<Cvs::Result::DiffItem>, L<Cvs::Result::DiffList>.

=head2 rdiff

    Cvs::Result::RdiffList =
      $cvs->rdiff("module", {from_revision => $rev}); 

L<Cvs::Result::RdiffList>.

=head2 log

    Cvs::Result::Log = $cvs->log();

L<Cvs::Result::Log>.

=head2 tag

    Cvs::Result::Tag = $cvs->tag("tag");

L<Cvs::Result::Tag>.

=head2 rtag

    Cvs::Result::Tag = $cvs->rtag("module", "tag");

L<Cvs::Result::Rtag>.

=head2 release

    Cvs::Result::Release = $cvs->release();

    Cvs::Result::Release = $cvs->release('module', ..., {force => 1});

Call the release command.

If call with no directories to release, self repository will be
released.

=over 4

=item force

Boolean value that activate a forced directory release even if some
files was not committed.  Defaults to false.

=item delete_after

Boolean value that activate directory removal after a release. Default
to false.

=back

L<Cvs::Result::Release>

=head2 export

    Cvs::Result::Export = $obj->export("module", {key => "value"});

Checkout the module "module" in the repository (the one that served to
create the Cvs object) from the cvsroot given in parameter, but without
the CVS administrative directories. 

Allowed parameters are the same as for checkout.  However, one of the 
options 'revision' or 'date' must be specified.

=head1 OTHERS METHODS

=cut

sub new
{
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $self = {};
    bless($self, $class);

    my $workdir = @_ % 2 ? shift : undef;
    my %args = @_;

    $self->debug($args{debug} or 0);

    # we need a full path
    if(defined $workdir)
    {
        $workdir =~ s/\/$//g;
        if($workdir =~ /^(.*\/)(.*)/)
        {
            $self->workdir($2);
            if(index($1, '/') == 0)
            {
                $self->pwd($1);
            }
            else
            {
                $self->pwd(cwd().'/'.$1);
            }
        }
        else
        {
            $self->workdir($workdir);
            $self->pwd(cwd().'/');
        }

        unless(-d $self->pwd())
        {
            $Cvs::ERROR = "Directory doesn't exists: ".$self->pwd();
            return;
        }

        if(not defined $args{cvsroot}
           and -f join('/', $self->working_directory(), 'CVS/Root'))
        {
            # trying to guess the cvsroot if working directory
            # exists... this will not work if cvsroot is - for example -
            # on a remote ssh server an need an interaction like a
            # password prompt
            my $_conf = new FileHandle
              join('/', $self->working_directory(), 'CVS/Root');
            if(defined $_conf)
            {
                $args{cvsroot} = $_conf->getline();
                chomp($args{cvsroot})
                  if defined $args{cvsroot};
            }
        }
    }
    else
    {
        $self->pwd(cwd().'/');
    }

    if(defined $args{cvsroot})
    {
        $self->cvsroot($args{cvsroot}, %args) or do
        {
            $Cvs::ERROR = $self->error();
            return;
        };
    }
    else
    {
        $Cvs::ERROR = 'Can\'t find CVSROOT';
        return;
    }

    return $self;
}

=pod

=head2 module_list

  my @modules = $cvs->module_list();

Returns the list of all modules which can be riched on the
CVSROOT. This method do something that cvs doesn't implement by itself,
we use a little trick to get this list, and this perhaps not work with
all cvs versions.

Do not mix up this method with the "-c" argument of the cvs' checkout
sub-command.

=cut

sub module_list
{
    my($self) = @_;

    my $cvsroot = $self->cvsroot()
      or return $self->error('Cannot determine CVSROOT');

    my $tmpdir = "/tmp/cvs-$$-".time();
    mkdir($tmpdir, 0700)
      or return $self->error("Cannot create directory: $tmpdir");
    chdir($tmpdir)
      or return $self->error("Cannot chdir to directory: $tmpdir");
    mkdir("$tmpdir/CVS")
      or return $self->error("Cannot create directory: $tmpdir/CVS");

    # create the Root control file
    my $root = new FileHandle ">$tmpdir/CVS/Root"
      or return $self->error("Cannot create file: $tmpdir/CVS/Root");
    $root->print($cvsroot->cvsroot() . "\n");
    $root->close();

    # create an empty Repository control file
    my $repository = new FileHandle ">$tmpdir/CVS/Repository"
      or return $self->error("Cannot create file: $tmpdir/CVS/Repository");
    $repository->print("\n");
    $repository->close();

    # keep some parameters
    my $old_pwd = $self->pwd();
    my $old_workdir = $self->workdir();
    $tmpdir =~ /^(.*\/)(.*)$/;
    $self->pwd($1);
    $self->workdir($2);

    # do the trick
    my $result =
      $self->update({send_to_stdout => 1, build_directories => 1});

    # cleanup and restore parameters
    rmtree($tmpdir);
    $self->pwd($old_pwd);
    $self->workdir($old_workdir);

    return $self->error($result->error())
      unless $result->success();

    return $result->ignored_directories();
}

=pod

=head1 ACCESSORS

=head2 cvsroot

Returns the Cvs::Cvsroot object.

=cut

sub cvsroot
{
    my($self, $cvsroot, %args) = @_;

    if(defined $cvsroot)
    {
        $self->{cvsroot} = new Cvs::Cvsroot $cvsroot, %args
          or return $self->error('Cannot init cvsroot object');
    }

    return $self->{cvsroot};
}

=pod

=head2 working_directory

Returns the full path of the working directory

=cut

sub working_directory
{
    my($self) = @_;
    return $self->pwd() . $self->workdir();
}

sub AUTOLOAD
{
    my $self = shift;

    my $name = $AUTOLOAD;
    $name =~ s/.*://;
    return if $name eq 'DESTROY';

    my $module = $self->load($name);
    my $cmd = $module->new($self, @_)
      or return $self->error($module->error());

    return $cmd->run();
}

sub load
{
    my($self, $name) = @_;
    $name = ucfirst $name;
    require "Cvs/Command/${name}.pm";
    return "Cvs::Command::$name";
}

sub error
{
    my($self, @msg) = @_;
    if(@msg)
    {
        $self->{_error} = join(' ', @msg);
        return undef;
    }
    else
    {
        return $self->{_error};
    }
}


1;
=pod

=head1 LICENCE

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as
published by the Free Software Foundation; either version 2.1 of the
License, or (at your option) any later version.

This library is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
USA

=head1 COPYRIGHT

Copyright (C) 2003 - Olivier Poitrey
