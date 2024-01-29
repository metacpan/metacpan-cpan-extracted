#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

use v5.36;
use Object::Pad 0.807;

class App::perl::distrolint::Check::Pod 0.06;

apply App::perl::distrolint::CheckRole::EachFile;
apply App::perl::distrolint::CheckRole::TreeSitterPerl;

use Text::Treesitter 0.10; # parse_string_range

use constant DESC => "check that every perl file contains some Pod";
use constant SORT => 30;

use List::Util qw( any first );

=head1 NAME

C<App::perl::distrolint::Check::Pod> - check that every Perl source file contains documentation

=head1 DESCRIPTION

This checks that Perl source code files contain at least one block of Pod.

Unit tests (named F<*.t>) and build-time generated source files (F<*.PL>) are
exempt from this check. Files in the F<examples/> directory are also skipped.

Additionally checks that each of the following C<=head1> sections appear:

   =head1 NAME
   =head1 DESCRIPTION
   =head1 AUTHOR

Additional checks are applied to the contents of various C<=head> sections.

=cut

method run ( $app )
{
   return $self->run_for_each_perl_file( check_file => );
}

my $HEAD_QUERY = <<'EOF';
(command_paragraph
   (command) @command
   _ @content) @para
(plain_paragraph
   _ @content) @para
(verbatim_paragraph
   _ @content) @para
EOF

method check_file ( $file )
{
   # .t and .PL files don't need Pod
   return 1 if $file =~ m/\.t$|\.PL$/;
   # Examples probably not either
   return 1 if $file =~ m/examples\//;
   # Anything in t/ is probably internal library or whatever
   return 1 if $file =~ m(^t/);

   my $tree = $self->parse_perl_file( $file );

   my @pod_nodes;

   $self->walk_each_query_match( '(pod) @pod', $tree->root_node, method ( $captures ) {
      push @pod_nodes, $captures->{pod};
   } );

   unless( @pod_nodes ) {
      App->diag( App->format_file( $file ), " has no Pod" );
      return 0;
   }

   state $TSPOD //= Text::Treesitter->new( lang_name => "pod" );

   my $text = $tree->text;

   my @head1_titles;
   my $last_head1;
   my %nodes_per_head1;

   my $ok = 1;

   foreach my $pod ( @pod_nodes ) {
      my $podtree = $TSPOD->parse_string_range( $text,
         node => $pod,
      );

      # We can't use ->walk_each_query_match because that presumes a query
      # based on t-s-perl
      state $QUERY = Text::Treesitter::Query->new(
         $TSPOD->lang, $HEAD_QUERY
      );

      my $qc = Text::Treesitter::QueryCursor->new;
      $qc->exec( $QUERY, $podtree->root_node );

      while( my $captures = $qc->next_match_captures ) {
         my $contentnode = $captures->{content};
         my $content = $contentnode->text;
         $content =~ s/\n// unless $contentnode->type eq "verbatim_paragraph";

         my $command = $captures->{command} ? $captures->{command}->text : undef;
         if( defined $command and $command eq "=head1" ) {
            push @head1_titles, $content;
            $last_head1 = $content;
         }
         else {
            push $nodes_per_head1{$last_head1 // ""}->@*, $captures->{para};

            if( $content =~ m/^\s*TODO\s*$/ ) {
               App->note( App->format_file( $file, $contentnode->start_row + 1 ), " contains a TODO paragraph in Pod" );
            }
         }

         if( ( $command // "" ) eq "=head2" and
             my $meth = $self->can( "check_head2_$last_head1" ) ) {
            $ok &= $meth->( $self, $file, $contentnode );
         }
      }
   }

   foreach my $title (qw( NAME DESCRIPTION AUTHOR )) {
      unless( any { $_ eq $title } @head1_titles ) {
         App->diag( App->format_file( $file ), " is missing a '=head1 $title' Pod section" );
         return 0;
      }
   }

   foreach my $title ( sort keys %nodes_per_head1 ) {
      my $meth = $self->can( "check_nodes_$title" ) or
         next;
      $meth->( $self, $file, ( $nodes_per_head1{$title} // [] )->@* ) or
         return 0;
   }

   return $ok;
}

=head2 Checks on C<NAME>

After a C<=head1 NAME> there should be exactly one paragraph, and its content
should match C<NAME - text>, where C<NAME> should match the module name
implied by the file's path, optionally wrapped in C<CE<lt>...E<gt>> formatting.

=cut

method check_nodes_NAME ( $file, @nodes )
{
   if( @nodes > 1 ) {
      App->diag( App->format_file( $file ), " has more than one paragraph under =head1 NAME" );
      return 0;
   }

   my $content = $nodes[0]->text =~ s/\n/ /gr;

   unless( $content =~ m/^C<(.*)> - (.*)$/ ) {
      App->diag( App->format_file( $file ), " =head1 NAME section does not look like C<Package::Name> - description" );
      return 0;
   }
   my ( $pkgname, $description ) = ( $1, $2 );

   $file =~ m{^lib/(.*).pm$} or return 1;
   my $pkgname_from_file = $1 =~ s{/}{::}gr;

   unless( $pkgname eq $pkgname_from_file ) {
      App->diag( App->format_file( $file ), " =head1 NAME section should start C<$pkgname_from_file> - ..." );
      return 0;
   }

   return 1;
}

=head2 Checks on C<FUNCTIONS> and C<METHODS>

For every C<=head2> inside C<=head1 FUNCTIONS> or C<=head1 METHODS>, the text
is checked to ensure it is a bareword function/method name, optionally
followed by other clarifying text after whitespace.

After every C<=head2> the next paragraph must be a verbatim paragraph,
presumed to contain the function's minsynopsis code. The contents of this
are also checked, to see that the first line looks like an example calling
the named function or method, that ends in a semicolon.

The function name can optionally be preceeded by a variable assignment to
indicate the return value (C<$var = ...> or C<($list, $of, @vars) = ...>),
optionally prefixed with C<my>. It can optionally be preceeded by a variable
containing the invocant name and a method call arrow (C<< $var->... >>). It
can optionally be followed by any other text in parentheses, to indicate the
arguments passed. It can optionally use an C<await> expression, used to
indicate it is a L<Future>-returning asynchronous function or method.

E.g.

   funcname;
   funcname(@args);
   $self->methodname(@args);
   $result = funcname(args, here);
   my ($return, $values) = Some::Package->methodname(some, more, args);
   my $response = await $client->call;

=cut

method check_head2_FUNCTIONS ( $file, $node ) { $self->_check_head2_func( $file, FUNCTIONS => $node ) }
method check_head2_METHODS   ( $file, $node ) { $self->_check_head2_func( $file, METHODS   => $node ) }

method _check_head2_func ( $file, $head1_title, $node )
{
   my $text = $node->text;
   if( $text !~ m/^(\w+)(?:\s+.*)?$/ ) {
      App->diag(
         App->format_file( $file, $node->start_row + 1 ),
         " $head1_title should be =head2 barename; is ",
         App->format_literal( $text ) );
      return 0;
   }

   return 1;
}

method check_nodes_FUNCTIONS ( $file, @nodes ) { $self->_check_nodes_func( $file, FUNCTIONS => @nodes ); }
method check_nodes_METHODS   ( $file, @nodes ) { $self->_check_nodes_func( $file, METHODS => @nodes ); }

method _check_nodes_func ( $file, $head1_title, @nodes )
{
   my $ok = 1;

   my $last_head2;

   while( @nodes ) {
      my $node = shift @nodes;
      my $type = $node->type;

      my $contentnode = first { $_->type eq "content" } $node->child_nodes;

      if( $type eq "command_paragraph" and $node->child_by_field_name( "command" )->text eq "=head2" ) {
         $last_head2 = $contentnode;
         my $funcname = ( split m/\s+/, $last_head2->text )[0];

         # Having just switched to a new head2 we immediately expect a verbatim paragraph

         # Though it's possible we might have more head2s first to give multiple headings
         while( @nodes and $nodes[0]->type eq "command_paragraph" and
                $nodes[0]->child_by_field_name( "command" )->text eq "=head2" ) {
            shift @nodes;
         }

         $node = shift @nodes;
         unless( $node and $node->type eq "verbatim_paragraph" ) {
            App->diag( App->format_file( $file, $last_head2->start_row + 1 ),
               " =head2 $funcname section should be followed by a verbatim paragraph" );
            $ok = 0;
            next;
         }

         my $minisynopsis = $node->text;
         $minisynopsis =~ s/^\s+//gm;

         my $VAR = qr/[\$\@\%]\w+/;
         my $VARS = qr/\(\s*$VAR(?:,\s*$VAR)*(?:,\s*\.\.\.)?\s*\)/;
         my $INVOCANT = qr/(?:\$\w+|(?:\w+::)*\w+)/;
         my $match = $minisynopsis =~ m/\A
            (?:(?:my\s+)?(?:$VAR | $VARS)\s+=\s+)? # var or (var...) =
            (?:await\s+)?
            (?:$INVOCANT->)?
            \Q$funcname\E
            (?:\(.*\))?                  # (args)
            /x;
         if( !$match )  {
            App->diag( App->format_file( $file, $node->start_row + 1 ),
               " minisynopsis should look like [[my] VAR(S) =] [await] [VAR->] $funcname [(ARGS...)];" );
            $ok = 0;
            next;
         }

         if( $minisynopsis !~ m/\A.*;$/sm ) {
            App->diag( App->format_file( $file, $node->start_row + 1 ),
               " minisynopsis first line should end with ';'" );
            $ok = 0;
            next;
         }
      }
   }

   return $ok;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
