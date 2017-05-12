#!/usr/bin/env perl

# vim: ts=3 sts=3 sw=3 et ai :
use feature 'state';
use lib '../lib';
use Data::Tubes qw< pipeline >;

my $input = <<'END';
a=Harry b=Sally
a=Jekyll b=Hide
a=Flavio b=Silvia
a=so{m}e b=<thin="g">
END

pipeline(

   # automatic loading for simple cases
   (
      qw<
        Source::iterate_files
        Reader::by_line
        Parser::hashy
        >,
   ),

   # a tube is a sub with a contract on the return value
   sub {
      my $record = shift;
      state $id = 0;
      $record->{structured}{sequence_id} = $id++;
      escape_html(values %{$record->{structured}});
      return $record;
   },

   # automatic loading with arguments
   [
      'Renderer::with_template_perlish',
      template => <<'END',
   <pair id="[% sequence_id %]">
      <item>[% a %]</item>
      <item>[% b %]</item>
   </pair>
END
   ],
   [
      'Writer::to_files',
      filename => \*STDOUT,
      header   => "<sequence>\n",
      footer   => "</sequence>\n"
   ],

   # options for tube, in this case just pour into the sink
   {tap => 'sink'}

)->([\$input]);

sub escape_html {
   my %_escape_table = (
      '&'  => '&amp;',
      '>'  => '&gt;',
      '<'  => '&lt;',
      q{"} => '&quot;',
      q{'} => '&#39;',
      q{`} => '&#96;',
      '{'  => '&#123;',
      '}'  => '&#125;'
   );
   $_ =~ s/([&><"'`{}])/$_escape_table{$1}/ge for @_;
} ## end sub escape_html
