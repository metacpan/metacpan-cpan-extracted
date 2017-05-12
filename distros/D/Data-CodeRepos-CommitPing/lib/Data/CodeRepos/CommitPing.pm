package Data::CodeRepos::CommitPing;

use strict;
use warnings;
our $VERSION = '0.03';

use Carp;
use DateTime;
use DateTime::Format::HTTP;
use YAML;

sub new {
    my($class, $stuff) = @_;
    croak 'usage: Data::CodeRepos::CommitPing->new($coderepos_commit_data)' unless $stuff;
    
    unless (ref $stuff eq 'HASH') {
        if (ref $stuff) {
            # if CGI object
            $stuff = eval { $stuff->param('yaml') };
            croak "bad object: $@" if $@;
        }
        $stuff = Load($stuff);
    }

    for my $key (qw/ author comment date files rev /) {
        croak 'invalid CodeRepos commit ping format' unless defined $stuff->{$key};
    }

    $stuff->{date} = DateTime::Format::HTTP->parse_datetime($stuff->{date});

    for (@{ $stuff->{files} }) {
        $_->{path_list} = [ split '/', $_->{path} ];
    }

    bless { %$stuff }, $class;
}

sub revision { shift->{rev} }
*rev = \&revision;
sub comment { shift->{comment} }
sub date { shift->{date} }
sub author { shift->{author} }
sub files { shift->{files} }

sub changes_base {
    my $self = shift;

    my $changes_projs = {};
    for my $file (@{ $self->{files} }) {
        next unless $file->{path_list}->[0];
        my $proj = 'proj_' . $file->{path_list}->[0];
        my $path = $self->$proj($file);
        $changes_projs->{$path}++;
    }

    for my $top ($self->toplevel_updates) {
        next unless $top->{status} eq '_U';
        my $path = join '/', @{ $top->{path_list} };
        delete $changes_projs->{$path};
    }

    my @ret;
    for my $path ( sort { $changes_projs->{$b} <=> $changes_projs->{$a} } keys %{ $changes_projs } ) {
        push @ret, $path;
    }
    return unless @ret;
    return @ret > 1 ? [ @ret ] : $ret[0];
}

sub toplevel_updates {
    my $self = shift;

    my @ret;
    for my $file (@{ $self->{files} }) {
        my @list = @{ $file->{path_list} };
        unless (($list[0] || '') eq 'lang' && ($list[2] || '') eq 'misc') {
            next if @list > 2;
        }
        push @ret, $file;
    }
    @ret;
}


# projects
# book  config  corp  dan  docs  dotfiles  lang  platform  poem  websites
our %PROJECT_BASE;
for my $proj (qw/ platform docs dan corp /) {
    $PROJECT_BASE{$proj} = 3;
}
for my $proj (qw/ config websites dotfiles poem book  /) {
    $PROJECT_BASE{$proj} = 2;
}

for my $proj (keys %PROJECT_BASE) {
    no strict 'refs';
    *{"proj_$proj"} = sub {
        use strict;
        my($self, $file) = @_;
        my @list = @{ $file->{path_list} };
        my $max = $PROJECT_BASE{$proj};
        $max = @list < $max ? scalar(@list) : $max;
        $max--;
        join '/', @list[0..$max];
    }
}

sub proj_lang {
    my($self, $file) = @_;
    my @list = @{ $file->{path_list} };
    my $max = scalar(@list) - 1;
    if ($list[2]) {
        if ($list[2] eq 'misc' || ($list[1] eq 'javascript' && $list[2] eq 'userscripts')) {
            $max = $list[3] ? 3 : 2;
        } else {
            $max = 2;
        }
    }
    join '/', @list[0..$max];
}


1;
__END__

=encoding utf8

=head1 NAME

Data::CodeRepos::CommitPing - CodeRepos commit ping data handler

=head1 SYNOPSIS

  use Data::CodeRepos::CommitPing;

  # from CGI data
  my $data = Data::CodeRepos::CommitPing->new(CGI->new);

  # from yaml data
  my $data = Data::CodeRepos::CommitPing->new(CGI->new->param('yaml'));

  # from HASH ref
  my $data = Data::CodeRepos::CommitPing->new({
      author  => 'yappo',
      comment => 'commit log',
      date    => '2008-02-08 14:59:11 +0900',
      files   => [
          {
              path   => 'websites/coderepos.org/scripts/commit-ping-hook.pl',
              status => 'U',
          },
      ],
      rev     => '6373',
  });

  print $data->revision; # 6373
  print $data->comment; # commit log
  print $data->author; # yappo
  print $data->date; # DateTime object
  print $data->files; # file list array ref

  print $data->changes_base; # websites/coderepos.org


=head1 DESCRIPTION

Data::CodeRepos::CommitPing is CodeRepos commit log parser and handler.

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

=head1 SEE ALSO

L<http://coderepos.org/share/>
L<http://coderepos.org/share/wiki/commit-ping/SITEINFO>

=head1 REPOSITORY

  svn co http://svn.coderepos.org/share/lang/perl/Data-CodeRepos-CommitPing/trunk Data-CodeRepos-CommitPing

Data::CodeRepos::CommitPing is Subversion repository is hosted at L<http://coderepos.org/share/>.
patches and collaborators are welcome.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
