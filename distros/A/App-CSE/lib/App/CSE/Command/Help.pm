package App::CSE::Command::Help;
$App::CSE::Command::Help::VERSION = '0.016';
use Moose;
extends qw/App::CSE::Command/;

use Pod::Text;
use Pod::Usage;

use Log::Log4perl;
my $LOGGER = Log::Log4perl->get_logger();

sub execute{
  my ($self) = @_;


  unless( $self->cse()->interactive() ){
    my $output;
    my $p2txt = Pod::Text->new();
    $p2txt->output_string(\$output);
    $p2txt->parse_file(__FILE__);
    $LOGGER->info("This is cse version ".$self->cse()->version());
    $LOGGER->info($output);
  }else{
    Pod::Usage::pod2usage( -input => __FILE__ , -verbose => 2,
                           -message => 'This is cse version '.$self->cse()->version()
                         );
  }
  return 1;
}

__PACKAGE__->meta->make_immutable();

__END__

=head1 NAME

App::CSE::Command::Help - cse's help

=head1 SYNOPSIS

  cse <command> [ .. options .. ] [ -- ] [ command arguments ]

  # Search for 'Something'
  cse Something

  # Search for 'search'
  cse search search

  # Check the index.
  cse check

=head1 COMMANDS

=head2 search

Searches the index for matches. Requires a query string. The name of the command is optional if you
are searching for a term that doesnt match a command.

Optionally, you can give a directory to retrict the search to a specific directory.

Examples:

   ## Searching for the word 'Something'
   cse Something

   ## Hello without world
   cse hello AND NOT world

   ## Same thing, but more 'Lucy-ish':
   cse hello -world

   ## Searching for the word 'search'
   cse search search

   ## Searching for the word 'Something' only in the directory './lib'
   cse search Something ./lib

   ## Searching for any term starting with 'some':
   cse search some*

   ## Search for some_method
   cse some_method

   ## Search for some_method declarations only:
   cse decl:some_method

   ## Search for some_method, excluding the files declaring it:
   cse some_method -decl:some_method

   ## Search for files where a given method is called:
   cse call:some_method

=head3 search syntax

In addition of searching for simple terms, cse supports "advanced" searches using Lucy/Lucene-like query syntax.

cse uses the L<Lucy> query syntax.

For a full description of the supported query syntax, look there:
URL<Lucy query syntax|https://metacpan.org/pod/distribution/Lucy/lib/Lucy/Search/QueryParser.pod>

Examples:

  # Searching 'hello' only in perl files:
  cse 'hello mime:application/x-perl'


  # Searching ruby in everything but ruby files:
  cse -- 'ruby -mime:application/x-ruby'

  # Note the '--' that prevents the rest of the command line to be interpreted as -options.

=head3 search options

=over

=item --offset (-o)

Offset in the result space. Defaults to 0.

=item --num (-n)

Number of result on one page. Defaults to 5.

=back

=head2 help

Output this message. This is the default command when nothing is specified.

=head2 check

Checks the health status of the index. Also output various useful things.

=head2 index

Rebuild the index from the current directory.

=head3 index options

=over

=item --dir

Directory to index. Defaults to current directory.

=back

=head2 update

Updates the files marked as dirty (after a search) in the index.

=head2 watch

Start a deamon to update the current index on changes. This will log to syslog.

If you use the dirty files marker feature, you should disable this as it
will keep the index in sync with your codebase. (See unwatch below).

=head2 unwatch

Stops the deamon that watches changes to maintain the current index.

=head1 COMMON OPTIONS

=over

=item --idx

Specifies the index. Default to 'current directory'/.cse.idx

=item --verbose (-v)

Be more verbose.

=back


=head1 IGNORING FILES

Just like you often want to ignore files managed by your CVS, you probably want cse to ignore some of your files
at index time.

To have cse ignore files, create a .cseignore file in your current directory and add one pattern to ignore per line.
Patterns should be compatible with L<Text::Glob> and are very similar to .gitignore patterns.

With a bit of luck, you should be able to just link .cseignore to your .gitignore and things should just work.

=head1 COPYRIGHT

Copyright 2014 Jerome Eteve.

This program is free software; you can redistribute it and/or modify it under the terms of the Artistic License v2.0.

See L<http://dev.perl.org/licenses/artistic.html>.

=cut
