use strict;
use warnings;
package App::Nopaste::Service::GitLab;
# ABSTRACT: Service provider for GitLab snippets

our $VERSION = '1.013';

use parent 'App::Nopaste::Service';

use JSON::MaybeXS;
use LWP::UserAgent;
use Path::Tiny;
use namespace::clean 0.19;

my $config;
sub config {
  return $config if $config;

  local *STDERR;

  for my $key (qw(host token)) {
    my $value = `git config gitlab.$key`;
    return ($config = {}) unless $value && ! $?;

    chomp $value;
    $config->{$key} = $value;
  }

  return $config;
}

sub available         { !! keys %{ __PACKAGE__->config } }
sub forbid_in_default { 0 }

sub nopaste {
    my $self = shift;
    $self->run(@_);
}

sub run {
    my ($self, %arg) = @_;
    my $ua = LWP::UserAgent->new;

    my $desc = $arg{desc} || $arg{filename} || "a gist from nopaste";

    my $filename = defined $arg{filename}
                 ? path($arg{filename})->basename
                 : 'nopaste';

    my $json = encode_json({
        title       => $desc,
        file_name   => $filename,
        visibility  => $arg{private} ? "private" : "internal",
        content     => $arg{text},
    });

    my $url = sprintf 'https://%s/api/v4/snippets', $self->config->{host};

    my $res = $ua->post(
        $url,
        'PRIVATE-TOKEN' => $self->config->{token},
        Content         => $json,
        Content_Type    => 'application/json',
    );

    return $self->return($res);
}

sub return {
    my ($self, $res) = @_;

    if ($res->is_error) {
        my $text = $res->status_line;
        if ($res->code == 401) {
            $text .= "\nYou may need set gitlab.token and gitlab.host in your .gitconfig";
        }
        return (0, "Failed: " . $text);
    }

    if (($res->header('Client-Warning') || '') eq 'Internal response') {
      return (0, "LWP Error: " . $res->content);
    }

    my $url = decode_json($res->content)->{web_url};

    return (0, "Could not find paste link.") unless $url;
    return (1, $url);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Nopaste::Service::GitLab - Service provider for GitLab snippets

=head1 VERSION

version 1.013

=head1 NAME

App::Nopaste::Service::GitLab - Service provider for GitLab snippets

=head1 VERSION

version 1.012

=for stopwords SIGNES snippets oauth plaintext

=head1 GitLab Authorization

In order to create snippets you have to get a token.  You can get this from the
Profile section of your GitLab install, under "personal access tokens."

In your ~/.gitconfig file, add a section like this:

    [gitlab]
    token = YOUR-TOKEN
    host  = your.gitlab-hostname.example.com

That's it!

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=App-Nopaste>
(or L<bug-App-Nopaste@rt.cpan.org|mailto:bug-App-Nopaste@rt.cpan.org>).

=head1 AUTHOR

Ricardo SIGNES, <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Shawn M Moore.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
