package App::oaf;

=pod

=head1 NAME

App::oaf - Output stdin as a GitHub/Slack/JIRA etc... formatted code, list, or quote

=head1 SYNOPSIS

Output as Format will read from stdin and output code, lists, or quotes
based on the provided options and/or environment variables.

  usage: oaf [-mps] [-f format] [-l lang] [--list[1]]
  Output stdin as code in the given format
    -f FORMAT Format to output, defaults to markdown
    --help    Display this message
    -l LANG   Programming language of stdin, if supported by FORMAT
    --list    Output a bullet point list using FORMAT, each line is a list item
    --list1   Output a numbered list using FORMAT, each line is a list item
    -m        Force multiline output, if supported by FORMAT
    -p        Print the supported formats and exit
    --quote   Output as a quote in FORMAT
    -s        Force single line output, if supported by FORMAT
    --version Print the version

=head1 EXAMPLES

Output as GitHub Flavored Markdown:

  cat some-code | oaf -f github -l perl
  ```perl
  my $n = foo();
  return unless $n > 100;
  ```

Output as MediaWiki:

  cat some-code | oaf -f mediawiki -l perl
  <syntaxhighlight lang="perl">
  my $n = foo();
  return unless $n > 100;
  </syntaxhighlight>

Output a Markdown list:

  echo -e "line1\nline2\nline3" | ./oaf --list
  * line1
  * line2
  * line3

Output a numbered list formatted for JIRA:

  echo -e "line1\nline2\nline3" | ./oaf --list1 -f jira
  # line1
  # line2
  # line3

=head1 INSTALLATION

Currently there are two ways to install.

This requires your system to have L<Perl|https://www.perl.org/get.html> installed.
Unless you're on Windows you probably have it (here in 2019).

=head2 Download

  curl -o oaf https://raw.githubusercontent.com/sshaw/output-as-format/master/oaf
  chmod 555 oaf

=head2 CPAN

  cpan App::oaf

=head1 SUPPORTED FORMATS & SERVICES

=over 2

=item * Bitbucket

=item * Disqus

=item * GitHub

=item * GitLab

=item * HipChat

=item * HTML

=item * JIRA

=item * Markdown

=item * MediaWiki

=item * Org-mode

=item * POD

=item * reStructuredText

=item * Slack

=back

=head1 DEFAULTS

Defaults can be set by the following environment variables:

=over 2

=item * C<OAF_FORMAT> - output format

=item * C<OAF_LANG> - input programming language

=back

The default format is Markdown. There is no default programming language.

=head1 AUTHOR

Skye Shaw (sshaw [AT] gmail.com)

=head1 SEE ALSO

L<copy-as-format|https://github.com/sshaw/copy-as-format> for Emacs, from which
this is based.

=head1 COPYRIGHT

Copyright (c) 2017-2019 Skye Shaw.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
