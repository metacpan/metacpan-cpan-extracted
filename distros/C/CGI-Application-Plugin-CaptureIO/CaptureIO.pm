package CGI::Application::Plugin::CaptureIO;

=pod

=head1 NAME

CGI::Application::Plugin::CaptureIO - Plug-in capture cache

=head1 VERSION

0.01

=head1 SYNOPSIS

  use Your::App;
  use CGI::Application::Plugin::CaptureIO;

=head1 DESCRIPTION

When all output contents are preserved in the cache, and the same next request is transmitted, 

it is a plug-in that outputs contents preserved in the cache. 

The effect is demonstrated as a load measures on the screen where the update is not very frequent

though there are a lot of requests. 

=cut

use strict;
use base qw(Exporter);
use Carp;
use Digest::SHA1;
use File::Find;
use File::Path;
use File::Spec;
use File::stat;
use Storable;

our(
    $CAPTURE_CLEAR,
    $CAPTURE_DEPTH,
    $CAPTURE_DIR,
    $CAPTURE_MODE,
    $CAPTURE_PREFIX,
    $CAPTURE_SEPARATOR,
    $CAPTURE_TTL,
    @EXPORT,
    $VERSION
    );

$CAPTURE_CLEAR     = 0;
$CAPTURE_DEPTH     = 4;
$CAPTURE_DIR       = "/tmp/cgiapp-capture/";
$CAPTURE_MODE      = "_capture_output";
$CAPTURE_PREFIX    = "cgiapp_capture-";
$CAPTURE_SEPARATOR = ":";
$CAPTURE_TTL       = 60;
@EXPORT            = qw(
                        add_non_capture_runmodes
                        capture_init
                        current_url
                        delete_non_capture_runmodes
                        );
$VERSION           = 0.01;

sub import {

    my $pkg = caller;

    $pkg->add_callback("init", \&_capture_init);
    $pkg->add_callback("prerun", \&_restore_capture);
    $pkg->add_callback("postrun", \&_store_capture);

    goto &Exporter::import;
}

=pod

=head1 METHOD

=head2 add_non_capture_runmodes

Runmode that doesn't preserve contents in the cache is set. 

Example:

  sub setup {
 
     my $self = shift;
     $self->run_modes(
                      mode => "mode1",
                      mode2 => "mode2",
                      non_capture => "non_capture",
                      non_capture2 => "non_capture2",
                     );
     # Neither runmode non_capture nor non_capture2 cache contents. 
     $self->add_non_capture_runmodes(qw(non_capture non_capture2));
  }

=cut

sub add_non_capture_runmodes {

    my($self, @runmodes) = @_;
    map { $self->{__CAP_CAPTUREIO_CONFIG}->{NON_CAPTURE_RM}->{$_} = 1 } @runmodes;
}

=pod

=head2 capture_init

It sets it in the early preserving capture. 

Option:

  capture_clear   : The contents capture file and the directory not referred to whenever capture_init is executed when setting
                    it to "1" are deleted. 
                    The file and the directory from which several or more are not accessed are deleted at 
                    the second set with capture_ttl option.
                    defualt 0

  capture_ttl     : Contents are acquired, and output from the contents capture file in second when the
                    contents capture file specified that it preserves contents once survival time (The unit: second)
                    with capture_ttl number's passing. 
                    default 60

  capture_dir     : Directory that preserves contents capture file. default /tmp/cgiapp-capture/

  non_capture_rm  : Runmode that doesn't preserve contents in the cache is set.


Example:

  sub cgiapp_init {
  
    my $self = shift;
    $self->capture_init(
                        capture_clear  => 0,
                        capture_ttl    => 60,
                        capture_dir    => "/home/akira/myapp/tmp",
                        non_capture_rm => [qw(non_capture1 non_capture2)],
                       );
  }

=cut

sub capture_init {

    my($self, %args) = @_;

    $self->{__CAP_CAPTUREIO_CONFIG} = {
                                       CAPTURE_CLEAR   => $args{capture_clear} || $CAPTURE_CLEAR,
                                       CAPTURE_DIGEST  => _create_digest($self),
                                       CAPTURE_TTL     => $args{capture_ttl} || $CAPTURE_TTL,
                                       CAPTURE_DIR     => $args{capture_dir} || $CAPTURE_DIR,
                                       NON_CAPTURE_RM  => (ref($args{non_capture_rm}) eq "ARRAY") ? { map { $_ => 1 } @{$args{non_capture_rm}} } : {},
                                      };

    if($self->{__CAP_CAPTUREIO_CONFIG}->{CAPTURE_CLEAR}){
# capture auto clear
        find(sub {
        
            my $ttl = $self->{__CAP_CAPTUREIO_CONFIG}->{CAPTURE_TTL};
            my $st = stat($_);
            if(-d $_ && (time - $st->atime) > $ttl){
                rmtree($File::Find::dir, 0);
            }elsif(-e $_ && -B $_){

                if($_ =~ /^$CAPTURE_PREFIX/ && (time - $st->atime) > $ttl){
                    unlink $File::Find::name;
                }
            }
        }, 
        $self->{__CAP_CAPTUREIO_CONFIG}->{CAPTURE_DIR});

    }
}

=pod

=head2 current_url

Current URL is returned. 

Example:

  sub mode1 {
 
     my $self = shift;

     # when current url is http://www.hogehoge.hoge/app?mode=mode1, http://www.hogehoge.hoge/app?mode=mode1 is stored in $current_url
     my $current_url = $self->current_url;
  }

=cut

# copy from Sledge Web Application Framework
sub current_url {

    my($self, $schema) = @_;
    $schema ||= ($ENV{HTTPS}) ? "https" : "http";
    return sprintf "%s://%s%s", $schema, $ENV{HTTP_HOST}, $ENV{REQUEST_URI};
}

=pod

=head2 delete_non_capture_runmodes

Runmode that doesn't preserve the capture contents set with add_non_capture_runmodes and 

capture_init is released. 

Example:

  $self->delete_non_capture_runmodes(qw(capture_mode1 capture_mode2));

=cut

sub delete_non_capture_runmodes {

    my($self, @runmodes) = @_;
    map {
        if(exists $self->{__CAP_CAPTUREIO_CONFIG}->{NON_CAPTURE_RM}->{$_}){
            delete $self->{__CAP_CAPTUREIO_CONFIG}->{NON_CAPTURE_RM}->{$_};
        }
    } @runmodes;
}

# ============================================================= #
#                      add_callback "init"                      #
# ============================================================= #
sub _capture_init {

    my $self = shift;
    $self->capture_init if !$self->{__CAP_CAPTUREIO_CONFIG};
}

# ============================================================= #
#                     add_callback "prerun"                     #
# ============================================================= #
sub _restore_capture {

    my($self, $rm) = @_;
    return if $ENV{REQUEST_METHOD} eq "POST";

    my $digest = $self->{__CAP_CAPTUREIO_CONFIG}->{CAPTURE_DIGEST};
    my $ttl = $self->{__CAP_CAPTUREIO_CONFIG}->{CAPTURE_TTL};
    my $capture_dir = _capture_dir($self);
    my $capture = File::Spec->catfile($capture_dir, $CAPTURE_PREFIX . $digest);

    if(-e $capture && -B $capture){

        my $st = stat($capture);
        if((time - $st->mtime) <= $ttl){

            my $ref = Storable::retrieve($capture);
            $self->run_modes( $CAPTURE_MODE => sub {
                
                    my $self = shift;
                    $self->header_props(%{$ref->{header}});
                    return ${$ref->{body}};
                });
            $self->prerun_mode($CAPTURE_MODE);
            $self->add_non_capture_runmodes($ref->{rm});

        }else{

            unlink $capture;
        }
    }

}

# ============================================================= #
#                     add_callback "postrun"                    #
# ============================================================= #
sub _store_capture {

    my($self, $scalarref) = @_;
    my $rm = $self->get_current_runmode;

# POST REQUEST or $CAPTURE_MODE(_capture_output) or non capture mode is non capture
    return if $ENV{REQUEST_METHOD} eq "POST";
    return if $CAPTURE_MODE eq $rm;
    return if exists $self->{__CAP_CAPTUREIO_CONFIG}->{NON_CAPTURE_RM}->{$rm};

    my %props = $self->header_props;
    my %header = (
                  -type    => $props{-type}    || "text/html",
                  -charset => $props{-charset} || "utf-8",
                 );
    my $capture_dir = _capture_dir($self);
    my $capture = File::Spec->catfile($capture_dir, $CAPTURE_PREFIX . $self->{__CAP_CAPTUREIO_CONFIG}->{CAPTURE_DIGEST});

# create capture directory
    eval { mkpath($capture_dir, 0) } if not -e $capture_dir;
    if($@){
        croak("Can not create directory $capture_dir [$@]");
    }

    Storable::nstore({ 
            body   => $scalarref,
            header => \%header,
            rm     => $rm,
        }, $capture);
}


sub _create_digest {

    my $self = shift;
    my $sha1 = Digest::SHA1->new;
    $sha1->add(join $CAPTURE_SEPARATOR, $self->current_url, $ENV{HTTP_USER_AGENT} || "nonbrowser/$VERSION");
    return $sha1->hexdigest;
}

sub _capture_dir {

    my $self = shift;
    my $capture_dir;
    my $len = 2;
    my @dirs;
    my($digest) = $self->{__CAP_CAPTUREIO_CONFIG}->{CAPTURE_DIGEST};
 
    push @dirs, $self->{__CAP_CAPTUREIO_CONFIG}->{CAPTURE_DIR};

    for(my $i = 0;$i < $CAPTURE_DEPTH;$i += $len){
        push @dirs, substr($digest, $i, $len);
    }
    return File::Spec->catfile(@dirs);
}

1;


__END__

=head1 TIPS

It preserves in the capture cash file in case of as it is runmode that it is runmode or is error_mode

specified with AUTOLOAD of $self->run_modes (Perhaps, when runmode that corresponds to the above-mentioned is called,

everybody : about contents it is to be sure not to have to preserve it by them),

and execute $self->add_non_capture_runmodes in AUTOLOAD and error_mode to make it not preserve,

please under the present situation. 

  # setup
  sub setup {
      my $self = shift;
      $self->start_mode("mode1");
      $self->mode_param("mode");
      $self->error_mode("error");
      $self->run_modes(
                      mode1 => "mode1",
                      mode2 => "mode2",
                      mode3 => "mode3",
                      mode4 => "mode4",
                      AUTOLOAD => "catch_exception",
                     );
  }
 
  # error mode
  sub error {
    my($self, $error) = @_;
    # require!!
    $self->add_non_capture_runmodes($self->get_current_runmode);
    # process start...
  }
 
  # AUTOLOAD mode
  sub catch_exception {
    my($self, $intended_runmode) = @_;
    # require!!
    $self->add_non_capture_runmodes(intended_runmode);
    # process start...
  }

=head1 NOTES

This plug-in obtains a large hint from B<Sledge::Plugin::CacheContents of Sledge Web Application Flamework>.

The function that Sledge and Sledge::Plugin::CacheContents are excellent can have been mounted as a plug-in of CGI::Application.

=head1 SEE ALSO

L<Carp> L<CGI::Application> L<Digest::SHA1> L<Exporter> L<File::Find> L<File::Path> L<File::Spec> L<File::stat> L<Storable>

=head1 AUTHOR

Akira Horimoto <emperor.kurt@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2006 Akira Horimoto

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

