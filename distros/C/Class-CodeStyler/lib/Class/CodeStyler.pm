# vim:ts=4 sw=4
# ----------------------------------------------------------------------------------------------------
#  Name		: Class::CodeStyler.pm
#  Created	: 24 April 2006
#  Author	: Mario Gaffiero (gaffie)
#
# Copyright 2006-2007 Mario Gaffiero.
# 
# This file is part of Class::CodeStyler(TM).
# 
# Class::CodeStyler is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
# 
# Class::CodeStyler is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with Class::CodeStyler; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
# ----------------------------------------------------------------------------------------------------
# Modification History
# When          Version     Who     What
# ----------------------------------------------------------------------------------------------------
package Class::CodeStyler;
require 5.005_62;
use strict;
use warnings;
use vars qw($VERSION $BUILD);
$VERSION = 0.27;
$BUILD = 'Tue May 01 18:32:42 GMTDT 2007';
use Carp qw(confess);
use stl;
# ----------------------------------------------------------------------------------------------------
{
	package Class::CodeStyler::Element::Abstract;
	use base qw(Class::STL::Element);
	use Class::STL::ClassMembers qw(owner);
	use Class::STL::ClassMembers::Constructor;
	sub prepare
	{
		confess __PACKAGE__ . "::prepare() -- pure virtual function must be overridden.";
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::CodeStyler::CodeText;
	use base qw(Class::STL::Containers::Stack);
	use Class::STL::ClassMembers
		Class::STL::ClassMembers::DataMember->new(name => 'newline_is_on',	default => 1),
		Class::STL::ClassMembers::DataMember->new(name => 'indent_is_on', default => 1),
		Class::STL::ClassMembers::DataMember->new(name => '_indent_next', default => 1),
		Class::STL::ClassMembers::DataMember->new(name => 'current_tab', default => 0),
		Class::STL::ClassMembers::DataMember->new(name => 'tab_type', default => 'spaces', validate => '(hard|spaces)'),
		Class::STL::ClassMembers::DataMember->new(name => 'tab_size', default => 2),
		Class::STL::ClassMembers::DataMember->new(name => 'debug', default => 0),
		Class::STL::ClassMembers::DataMember->new(name => 'raw_is_on', default => 0);
	use Class::STL::ClassMembers::Constructor;
	sub append_newline 
	{
		my $self = shift;
		return if ($self->raw_is_on());
		$self->push($self->factory(data => "\n"));
		$self->_indent_next(1);
		print STDERR "NEWLINE:\n" if ($self->debug());
	}
	sub append_text
	{
		my $self = shift;
		my $code = shift || '';
		$self->push($self->factory(data => $self->current_indent() . $code));
		print STDERR "CODE   :@{[ $self->current_indent() ]}${code}\n" if ($self->debug());
		$self->_indent_next(0);
	}
	sub current_indent
	{
		my $self = shift;
		return '' if ($self->raw_is_on());
		return '' if (!$self->indent_is_on());
		return '' unless ($self->_indent_next());
		my $tabchar = $self->tab_type() eq 'hard' ? "\t" : ' ';
		return ($tabchar x ($self->current_tab() * $self->tab_size()));
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::CodeStyler::FindName;
	use base qw(Class::STL::Utilities::FunctionObject::UnaryFunction);
	use Class::STL::ClassMembers qw( name );
	use Class::STL::ClassMembers::Constructor;
	sub function_operator
	{
		my $self = shift;
		my $arg = shift; # element object
		return $arg->program_name() eq $self->name() ? $arg : 0;
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::CodeStyler::Program::Abstract;
	use base qw(Class::CodeStyler::Element::Abstract);
	use stl qw( find_if stack list iterator find for_each mem_fun );
	use UNIVERSAL qw(isa can);
	use Class::STL::ClassMembers 
	(
		qw(
			program_name segments code_text 
			_bracket_stack _parent _insert_point _jump_stack _over_stack _anchor_stack
		),
		Class::STL::ClassMembers::DataMember->new(name => 'suppress_comments', default => 0),
		Class::STL::ClassMembers::DataMember->new(name => 'tab_size', default => 2),
		Class::STL::ClassMembers::DataMember->new(name => 'tab_type', default => 'spaces', validate => '(hard|spaces)'),
		Class::STL::ClassMembers::DataMember->new(name => 'debug', default => 0),
		Class::STL::ClassMembers::DataMember->new(name => 'divider_length', default => 70),
		Class::STL::ClassMembers::DataMember->new(name => 'divider_char', default => '-'),
		Class::STL::ClassMembers::DataMember->new(name => 'comment_start_char', default => '#'),
		Class::STL::ClassMembers::DataMember->new(name => 'comment_block_begin_char', default => ''),
		Class::STL::ClassMembers::DataMember->new(name => 'comment_block_end_char', default => ''),
		Class::STL::ClassMembers::DataMember->new(name => 'comment_block_char', default => ''),
		Class::STL::ClassMembers::DataMember->new(name => 'disable_newline', default => 0),
		Class::STL::ClassMembers::DataMember->new(name => 'print_bookmarks', default => 0),
		Class::STL::ClassMembers::DataMember->new(name => 'open_block_on_newline', default => 1),
	);
	use Class::STL::ClassMembers::Constructor;
	sub exists
	{
		my $self = shift;
		my $name = shift;
		my @l = grep($_->program_name() eq $name, $self->to_array());
		return $l[0] if (@l);
		return 0;
	}
#?	sub exists #TODO: memleak? slow?
#?	{
#?		my $self = shift;
#?		my $name = shift;
#?		my $s;
#?		return $s->p_element()
#?			if ($s = find_if($self->segments()->begin(), $self->segments()->end(), 
#?				Class::CodeStyler::FindName->new(name => $name)));
#?		return 0;
#?	}
	sub new_extra
	{
		my $self = shift;
		$self->code_text(Class::CodeStyler::CodeText->new(
				debug => $self->debug(),
				tab_size => $self->tab_size(),
				tab_type => $self->tab_type(),
			))
			unless (defined($self->code_text()));
		$self->segments(list(element_type => 'Class::CodeStyler::Element::Abstract'));
		$self->_bracket_stack(stack());
		$self->_jump_stack(stack());
		$self->_anchor_stack(stack());
		$self->_over_stack(stack());
		$self->_insert_point(iterator($self->segments()->begin()));
		return $self;
	}
	sub add
	{
		my $self = shift;
		foreach my $code (@_)
		{
			confess "@{[ __PACKAGE__ ]}->add(): Undefined object!" unless (defined($code));
			if (ref($code) && $code->isa(__PACKAGE__))
			{
				$code->code_text($self->code_text());
				$code->_parent($self);
				map
				(
					$self->add($_), 
					grep
					(
						!$_->isa('Class::CodeStyler::Bookmark') || !find($self->segments()->begin(), $self->segments()->end(), $_->data()),
						$code->segments()->to_array()
					)
				);
				next;
			}
			elsif (ref($code) && $code->isa('Class::CodeStyler::Element::Abstract'))
			{
				$code->owner($self);
				$self->segments()->insert($self->_insert_point(), 1, $code);
			}
			elsif (!ref($code))
			{
				$self->add(Class::CodeStyler::Code->new(code => $code));
				next;
			}
			else
			{
				next;
			}
		}
	}
	sub code
	{
		my $self = shift;
		my $code = @_ ? shift : '';
		$self->add(Class::CodeStyler::Code->new(code => $code));
	}
	sub open_block
	{
		my $self = shift;
		my $bracket = shift || '{';
		my %_bracket_pairs = ( '(' => ')', '{' => '}', '[' => ']', '<' => '>' );
		$self->add(Class::CodeStyler::OpenBlock->new(bracket_char => $bracket));
		$self->_bracket_stack()->push($self->_bracket_stack()->factory($_bracket_pairs{$bracket}));
		return;
	}
	sub close_block
	{
		my $self = shift;
		return unless ($self->_bracket_stack()->size()); #ignore unmatched 'open_block'
		my $bracket = $self->_bracket_stack()->top()->data();
		$self->_bracket_stack()->pop();
		$self->add(Class::CodeStyler::CloseBlock->new(bracket_char => $bracket));
		return;
	}
	sub newline_on
	{
		my $self = shift;
		$self->add(Class::CodeStyler::ToggleNewline->new(on => 1));
	}
	sub newline_off
	{
		my $self = shift;
		$self->add(Class::CodeStyler::ToggleNewline->new(on => 0));
	}
	sub indent_on
	{
		my $self = shift;
		$self->add(Class::CodeStyler::ToggleIndent->new(on => 1));
	}
	sub indent_off
	{
		my $self = shift;
		$self->add(Class::CodeStyler::ToggleIndent->new(on => 0));
	}
	sub over
	{
		my $self = shift;
		my $indent = shift || 1;
		$self->add(Class::CodeStyler::Indent->new(indent => $indent));
		$self->_over_stack()->push($self->_over_stack()->factory($indent));
		return;
	}
	sub back
	{
		my $self = shift;
		return unless ($self->_over_stack()->size()); #ignore unmatched 'back'
		$self->add(Class::CodeStyler::Indent->new(indent => -($self->_over_stack()->top()->data())));
		$self->_over_stack()->pop();
		return;
	}
	sub comment
	{
		my $self = shift;
		my $txt = shift;
		$self->add(Class::CodeStyler::Comment->new(data => $txt));
	}
	sub divider
	{
		my $self = shift;
		$self->add(Class::CodeStyler::Divider->new());
	}
	sub anchor_set
	{
		my $self = shift;
		$self->add(Class::CodeStyler::Anchor->new(data => "@{[ 
				$self->_insert_point()->at_end() 
					? $self->_insert_point()->p_container()->size() 
					: $self->_insert_point()->arr_idx() 
			]}"));
		$self->_anchor_stack()->push($self->_insert_point()->prev()->clone());
	}
	sub anchor_return
	{
		my $self = shift;
		return unless($self->_anchor_stack()->size());
		$self->_insert_point($self->_anchor_stack()->top()->clone());
		$self->_anchor_stack()->pop();
	}
	sub bookmark
	{
		my $self = shift;
		my $id = shift;
		$self->add(Class::CodeStyler::Bookmark->new(data => $id));
	}
	sub jump
	{
		my $self = shift;
		my $id = shift;
		my $found;
		#TODO: potential bug if comment.data same as bookmark.data (id)!
		if ($found = find($self->segments()->begin(), $self->segments()->end(), $id))
		{
			$self->_jump_stack()->push($self->_insert_point()->clone());
			$self->_insert_point($found);
			return $found;
		}
		return 0;
	}
	sub return
	{
		my $self = shift;
		return unless($self->_jump_stack()->size());
		$self->_insert_point($self->_jump_stack()->top()->clone());
		$self->_jump_stack()->pop();
	}
	sub clear
	{
		my $self = shift;
		$self->code_text()->clear();
		return $self;
	}
	sub prepare
	{
		my $self = shift;
		# This works because all 'segments' elements are (ultimately) derived 
		# from Class::CodeStyler::Element::Abstract. Recursion via this prepare() will
		# occure if the element is a Class::CodeStyler::Program.
#?		for_each($self->segments()->begin(), $self->segments()->end(), mem_fun('prepare')); #TODO: memleak? slow?
		map($_->prepare(), $self->segments()->to_array());
		return $self;
	}
	sub print
	{
		my $self = shift;
		return $self->code_text()->join(''); 
		# Class::STL::Containers function -- joins print() return for all elements;
	}
	sub raw
	{
		my $self = shift;
		$self->code_text()->raw_is_on(1);
		$self->code_text()->clear();
		$self->prepare();
		my $txt = $self->print();
		$self->code_text()->raw_is_on('0');
		return $txt;
	}
	sub save
	{
		my $self = shift;
		my $filename = shift || $self->program_name();
		confess "save() -- Unable to save -- 'program_name' is not defined."
			unless defined($filename);
		open(SAVE, ">@{[ $filename ]}");
		print SAVE $self->print();
	}
	sub display
	{
		my $self = shift;
		my $line_number = 1;
		my @p;
		foreach (split(/\n/, $self->print()))
		{
			push(@p, sprintf(" %5d %s", $line_number++, $_));
		}
		return join("\n", @p);
	}
	sub syntax_check
	{
		my $self = shift;
		$self->save("@{[ $self->program_name() ]}.DEBUG");
		my $check = `perl -cw @{[ $self->program_name() ]}.DEBUG 2>&1`;
		chomp($check);
		if ($check !~ /syntax OK/i)
		{
			$self->code("__END__");
			$self->code("Syntax check summary follows:");
			$self->code("$check");
			$self->clear();
			$self->prepare();
			$self->save("@{[ $self->program_name() ]}.DEBUG");
		}
		else
		{
			unlink "@{[ $self->program_name() ]}.DEBUG";
		}
		return $check;
	}
	sub exec
	{
		my $self = shift;
		$self->save("@{[ $self->program_name() ]}.EXEC");
		exec("perl @{[ $self->program_name() ]}.EXEC");
	}
	sub run
	{
		my $self = shift;
		$self->save("@{[ $self->program_name() ]}.EXEC");
		system("perl @{[ $self->program_name() ]}.EXEC");
	}
	sub eval
	{
		my $self = shift;
		my $code = $self->print();
		eval($code);
		confess "**Error in eval:\n$@" if ($@);
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::CodeStyler::Program::Perl; 
	use base qw(Class::CodeStyler::Program::Abstract);
	use Class::STL::ClassMembers;
	use Class::STL::ClassMembers::Constructor;
	sub new_extra
	{
		my $self = shift;
		$self->comment_start_char('#');
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::CodeStyler::Program::C; 
	use base qw(Class::CodeStyler::Program::Abstract);
	use Class::STL::ClassMembers;
	use Class::STL::ClassMembers::Constructor;
	sub new_extra
	{
		my $self = shift;
		$self->comment_start_char('//');
		$self->comment_block_begin_char('/*');
		$self->comment_block_char      (' *');
		$self->comment_block_end_char  (' */');
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::CodeStyler::Program::Pod; 
	use base qw(Class::CodeStyler::Program::Abstract);
	use Class::STL::ClassMembers qw( title version type user_email author pdf );
	use Class::STL::ClassMembers::Constructor;
	sub new_extra
	{
		my $self = shift;
		$self->comment_start_char('=cut ');
		$self->code("=pod");
		$self->code();
	}
	sub head1
	{
		my $self = shift;
		my $code = shift || '';
		$self->code('=head1 ' . $code);
		$self->code();
	}
	sub head2
	{
		my $self = shift;
		my $code = shift || '';
		$self->code('=head2 ' . $code);
		$self->code();
	}
	sub head3
	{
		my $self = shift;
		my $code = shift || '';
		$self->code('=head3 ' . $code);
		$self->code();
	}
	sub head4
	{
		my $self = shift;
		my $code = shift || '';
		$self->code('=head4 ' . $code);
		$self->code();
	}
	sub begin
	{
		my $self = shift;
		my $code = shift || '';
		$self->code('=begin ' . $code);
		$self->code();
	}
	sub end
	{
		my $self = shift;
		my $code = shift || '';
		$self->code('=end ' . $code);
		$self->code();
	}
	sub item
	{
		my $self = shift;
		my $code = shift || '';
		$self->code();
		$self->code('=item ' . $code);
		$self->code();
	}
	sub literal
	{
		my $self = shift;
		my $code = shift || '';
		$self->code(' ' . $code);
		$self->code();
	}
	sub page
	{
		my $self = shift;
		$self->code('=page');
		$self->code();
	}
	sub over
	{
		my $self = shift;
		my $indent = shift;
		$self->code("=over @{[ defined($indent) ? $indent : '' ]}");
		$self->code();
	}
	sub back
	{
		my $self = shift;
		$self->code('=back ');
		$self->code();
	}
	sub to_pdf
	{
#>		$self->pdf(Class::CodeStyler::Pod2Pdf->new(
#>			title => $self->title(),
#>			version => $self->version(), 
#>			type => $self->type(), 
#>			email => $self->user_email(), 
#>			author => $self->author(), 
#>		));
#>		$self->pdf()->produce();
	}
}
# ----------------------------------------------------------------------------------------------------
{
package Class::CodeStyler::Anchor;
use base qw(Class::CodeStyler::Element::Abstract);
	use Class::STL::ClassMembers;
	use Class::STL::ClassMembers::Constructor;
	sub prepare
	{
		my $self = shift;
		return unless ($self->owner()->print_bookmarks());
		return if ($self->owner()->code_text()->raw_is_on());
		$self->owner()->code_text()->append_text("# ANCHOR ---- @{[ $self->data() ]}");
		$self->owner()->code_text()->append_newline();
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::CodeStyler::Bookmark;
	use base qw(Class::CodeStyler::Element::Abstract);
	use Class::STL::ClassMembers;
	use Class::STL::ClassMembers::Constructor;
	sub prepare
	{
		my $self = shift;
		return unless ($self->owner()->print_bookmarks());
		return if ($self->owner()->code_text()->raw_is_on());
		$self->owner()->code_text()->append_text("# BOOKMARK ---- @{[ $self->data() ]}");
		$self->owner()->code_text()->append_newline();
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::CodeStyler::OpenBlock;
	use base qw(Class::CodeStyler::Element::Abstract);
	use Class::STL::ClassMembers qw(bracket_char);
	use Class::STL::ClassMembers::Constructor;
	sub prepare
	{
		my $self = shift;
		$self->owner()->code_text()->append_text($self->bracket_char());
		return unless ($self->owner()->code_text()->newline_is_on());
		$self->owner()->code_text()->current_tab($self->owner()->code_text()->current_tab()+1);
		$self->owner()->code_text()->append_newline();
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::CodeStyler::CloseBlock;
	use base qw(Class::CodeStyler::Element::Abstract);
	use Class::STL::ClassMembers qw(bracket_char);
	use Class::STL::ClassMembers::Constructor;
	sub prepare
	{
		my $self = shift;
		$self->owner()->code_text()->current_tab($self->owner()->code_text()->current_tab()-1) if ($self->owner()->code_text()->newline_is_on());
		$self->owner()->code_text()->append_text($self->bracket_char());
		$self->owner()->code_text()->append_newline() if ($self->owner()->code_text()->newline_is_on());
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::CodeStyler::Code;
	use base qw(Class::CodeStyler::Element::Abstract);
	use Class::STL::ClassMembers qw(code);
	use Class::STL::ClassMembers::Constructor;
	sub prepare
	{
		my $self = shift;
		confess "Undefined 'owner' (@{[ $self->code() ]})!" unless (defined($self->owner()));
		$self->owner()->code_text()->append_text($self->code());
		$self->owner()->code_text()->append_newline() if ($self->owner()->code_text()->newline_is_on());
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::CodeStyler::Comment;
	use base qw(Class::CodeStyler::Element::Abstract);
	use Class::STL::ClassMembers;
	use Class::STL::ClassMembers::Constructor;
	sub prepare
	{
		my $self = shift;
#>		return if ($self->owner()->code_text()->raw_is_on());
		$self->owner()->code_text()->append_text($self->owner()->comment_start_char() . $self->data());
		$self->owner()->code_text()->append_newline() if ($self->owner()->code_text()->newline_is_on());
	}
}
# ----------------------------------------------------------------------------------------------------
{#TODO:
	package Class::CodeStyler::CommentBegin;
}
# ----------------------------------------------------------------------------------------------------
{#TODO:
	package Class::CodeStyler::CommentEnd;
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::CodeStyler::Divider;
	use base qw(Class::CodeStyler::Element::Abstract);
	use Class::STL::ClassMembers;
	use Class::STL::ClassMembers::Constructor;
	sub prepare
	{
		my $self = shift;
		$self->owner()->code_text()->append_text($self->owner()->comment_start_char());
		$self->owner()->code_text()->append_text($self->owner()->divider_char() x $self->owner()->divider_length());
		$self->owner()->code_text()->append_newline() if ($self->owner()->code_text()->newline_is_on());
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::CodeStyler::ToggleNewline;
	use base qw(Class::CodeStyler::Element::Abstract);
	use Class::STL::ClassMembers qw(on);
	use Class::STL::ClassMembers::Constructor;
	sub prepare
	{
		my $self = shift;
		$self->owner()->code_text()->newline_is_on($self->on());
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::CodeStyler::ToggleIndent;
	use base qw(Class::CodeStyler::Element::Abstract);
	use Class::STL::ClassMembers qw(on);
	use Class::STL::ClassMembers::Constructor;
	sub prepare
	{
		my $self = shift;
		$self->owner()->code_text()->indent_is_on($self->on());
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::CodeStyler::Indent;
	use base qw(Class::CodeStyler::Element::Abstract);
	use Class::STL::ClassMembers qw(indent);
	use Class::STL::ClassMembers::Constructor;
	sub prepare
	{
		my $self = shift;
		$self->owner()->code_text()->current_tab($self->owner()->code_text()->current_tab()+$self->indent());
	}
}
# ----------------------------------------------------------------------------------------------------
#TODO: User can extend Class::CodeStyler::Element::Abstract to provide specific code-blocks...
1;
