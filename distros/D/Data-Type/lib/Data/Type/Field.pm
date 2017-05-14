
# (c) 2004 by Murat Uenalan. All rights reserved. Note: This program is
# free software; you can redistribute it and/or modify it under the same
# terms as perl itself
# $Revision: 1.1 $
# $Header: /cygdrive/y/cvs/perl/modules/Data/Type/Type/Field.pm.tmpl,v 1.1 2003/04/02 11:38:22 Murat Exp $

package Data::Type::Field;

use Attribute::Util;

Class::Maker::class
{
    public => 
    {
	string => 
	[ 
	  'mask' # => '(###)-###-####)'   # a simple mask for input prompt (in this example a telefon number
        ], 
	
	scalar => 
	[
	 'type',         # type => STD::EMAIL(),
	 'desc',         # desc => 'more complete textual description',
	 'prompt',       # prompt => 'Do you accept this',
	 'usage',        # usage => [yes|no]
	 'default',      # default => 'yes',
	 'required',     # required => 1
	 ],
	
	array => 
	[
	 'filters',          # Data::Type::Filter's as for Data::Type's (L<Data::Type::Filter>).
	 ],
	
     },
};

package Data::Type::Field::OneOfMany;  # yes/no, true/false, 

  our @ISA = qw(Data::Type::Field);

package Data::Type::Field::ManyOfMany;  

  our @ISA = qw(Data::Type::Field);

sub get_from_shell : method
{
    my $this = shift;
    
    my ($desc, $choices, $default) = @_;

    my $tries = 1;

    local $| = 1;

    my ( $default_choice, $cnt ) = ( 0, 0 );

    print $desc, "\n";

    for ( @$choices ) 
    { 
	$cnt++;

	printf "  %d) %s %s\n", $cnt, $_, $default eq $_ ? '(default)' : '';
	
	$default_choice = $cnt if $default eq $_;
    }

    while (1) 
    {	    
	print "Select item 1-$cnt [$default_choice]: ";

	chomp(my $input=<STDIN>);

	no warnings;

	my $answer = defined $input ? $input+0 : $default_choice;

	return $choices->[$answer-1] if $answer >= 0 && $answer <= $cnt;

	print "Please choose from 1 - $cnt\n";

	print "And quit screwing around.\n" and $tries = 0 if ++$tries > 3;
    }
}

1;

__END__

package Data::Type::Field::Form::Field;

Class::Maker::class { isa => [qw( MasonX::Widget )],

	public =>
	{
		string => [qw( accesskey label vtype vstatus )],
	},
	
	default => 
	{
		vstatus => '',
	},
};

=head1 Method B<js_onfocus>

=cut

sub js_onfocus
{
return 'if (this.value==this.defaultValue) this.select()';
}

package Data::Type::Field::Form::Label;

our $ak = Keyboard::Shortcut->new();

Class::Maker::class { isa => [qw( Data::Type::Field::Grid MaxonX::Container )],

	public =>
	{
		int 	=> [qw( selectable )],

		string 	=> [qw( text )],

		array 	=> [qw( position )],
	},

	default => 
	{
		selectable => 1,

		position => [ 0, 1 ],
	},
};

sub _preinit
{
	my $this = shift;

		if( defined $this->cx || defined $this->cy )
		{
			$this->position( $this->cx, $this->cy );
		}
}

sub to_html : method
{
	my $this = shift;

		if( my $text = $this->text )
		{
			if( $this->selectable )
			{
				$ak->string( $text );

				my $akey = $ak->getkey();

				$text = $ak->string(); # possible '_' are filtered

				unless( $ak->guessed() )
				{
					$text =~ s/$akey/<u>$akey<\/u>/;
				}
				else
				{
					$text .= $Data::Type::Field::XML->span( { class => 'hotkey' }, $ak->hotkey() );
				}

				$text = join '',$Data::Type::Field::XML->label( { accesskey => $akey, for => $this->contains->id }, $text );
			}

			$this->place( @{ $this->position }, $text );
		}

		if( $this->contains )
		{
				# place our gadget into the middle
			$this->place( 'center' , $this->contains );

			$this->place( qw(mid right), $this->contains->vstatus ) if $this->contains->isa( 'Data::Type::Field::Form::Field' );
		}

		#$this->place( qw(mid right), $this->id );

			# caption name..
		#$this->name( $this->contains->name ) if ref( $this->contains );

return $this->Data::Type::Field::Grid::to_html();
}

package Data::Type::Field::Form::Input;

Class::Maker::class { isa => [qw( MasonX::Widget )],

	public =>
	{
		string => [qw( type default )],
	},
};

package Data::Type::Field::Form::Field::Button;

Class::Maker::class { isa => [qw( Data::Type::Field::Form::Field Data::Type::Field::Form::Input )],

	default => 
	{
		default => 'Submit',
		
		type => 'submit',
	},
};

=head1

<input type="reset" />
<input type="submit" name=".defaults" value="Default" />
<input type="submit" name="submit" value="Submit" />

=cut

sub to_html : method
{
	my $this = shift;

return $Data::Type::Field::XML->input( {

	id 		=> $this->id,
	class 	=> $this->default,

	type 	=> $this->type,
	name 	=> $this->name,
	value 	=> $this->default,

	});

}

package Data::Type::Field::Form::Field::Checkbox;

Class::Maker::class { isa => [qw( Data::Type::Field::Form::Field Data::Type::Field::Form::Input)],

	public =>
	{
		int => [qw(default)],

		string => [qw(value)],
	},

	default => 
	{
		type => 'checkbox',
		
		value => 1,
	},
};

sub to_html : method
{
	my $this = shift;

	my $href_attr =
	{
		id 		=> $this->id,
		class 	=> $this->type,

		type	=> $this->type,
		name	=> $this->name,
		value	=> $this->value,
	};

	$href_attr->{checked} = 'checked' if $this->default;

	my @html = $Data::Type::Field::XML->input( $href_attr );

return @html;
}

package Data::Type::Field::Form::Field::File;

Class::Maker::class { isa => [qw( Data::Type::Field::Form::Field Data::Type::Field::Form::Input)],

	public =>
	{
		int => [qw(size maxlength)],

		string => [qw(default)],
	},

	default => 
	{
		type => 'file',
		
		size => 15,
		
		maxlength => 20,
	},
};

=head1

<input type="file" name="file" value="filename" />

=cut

sub to_html : method
{
	my $this = shift;

	my @html = $Data::Type::Field::XML->input( {

		id 	=> $this->id,
		class 	=> $this->type,

		type	=> $this->type,
		name	=> $this->name,
		size	=> $this->size,
		value	=> $this->default,
		maxlength=> $this->maxlength,

		ONFOCUS	=> $this->js_onfocus,

	});

return @html;
}

package Data::Type::Field::Form::Field::Group;

Class::Maker::class { isa => [qw( MasonX::Widget )]
	
};

package Data::Type::Field::Form::Field::Hidden;

Class::Maker::class { isa => [qw( Data::Type::Field::Form::Field Data::Type::Field::Form::Input)],

	public =>
	{
		array => [qw(default)],
	},

	default => 
	{
	},
};

sub to_html : method
{
	my $this = shift;

return CGI::hidden( $this->name, @{ $this->default } );
}

package Data::Type::Field::Form::Field::List;

Class::Maker::class { isa => [qw( Data::Type::Field::Form::Field )],

	public =>
	{
		int => [qw( size multiple )],

		hash => [qw( labels )],

		array => [qw( values default )],
	},

	default => 
	{
		size => 5,
		
		multiple => 'true',
	},
};

=head1

<select name="PLASTIK" size="5" multiple>
	<option selected value="eenie">You now it..</option>
	<option  value="meenie">meenie</option>
	<option  value="minie">minie</option>
	<option selected value="moe">moe</option>
</select>

=cut

sub to_html : method
{
	my $this = shift;

	my @fields;

	foreach my $val ( @{ $this->values } )
	{
		my $href_attr = {value => $val};

		map { $href_attr->{selected} = 'selected' if $_ eq $val } @{$this->default};

		push @fields, $Data::Type::Field::XML->option( $href_attr, $this->labels->{$val} || $val );
	}

	my $href_attr =
	{
		id 		=> $this->id,
		class 	=> 'list',

		name	=> $this->name,
		size	=> $this->size,
	};

	$href_attr->{multiple} = 'true' if $this->multiple;

	my @html = $Data::Type::Field::XML->select( $href_attr, @fields );

return @html;
}

package Data::Type::Field::Form::Field::Password;

Class::Maker::class { isa => [qw( Data::Type::Field::Form::Field Data::Type::Field::Form::Input)],

	public =>
	{
		int => [qw(size maxlength)],

		string => [qw(default)],
	},

	default => 
	{
		type => 'password',
		
		size => 15,
		
		maxlength => 20,
	},
};

sub to_html : method
{
	my $this = shift;

	my @html = $Data::Type::Field::XML->input( {

		id 		=> $this->id,
		class 	=> $this->type,

		type	=> $this->type,
		name	=> $this->name,
		size	=> $this->size,
		value	=> $this->default,
		maxlength=> $this->maxlength,

		ONFOCUS	=> $this->js_onfocus,

	});

return @html;
}

package Data::Type::Field::Form::Field::Popup;

Class::Maker::class { isa => [qw( Data::Type::Field::Form::Field )],

	public =>
	{
		string => [qw(default)],

		hash => [qw(labels)],

		array => [qw(values)],
	},
};

=head1

<select name="PLASTIK">
<option  value="eenie">Your first choice</option>
<option  value="meenie">meenie</option>
<option  value="minie">minie</option>
</select>

=cut

sub to_html : method
{
	my $this = shift;

	my @fields;

	foreach ( @{ $this->values } )
	{
		my $attribs = { value => $_ };
		
		$attribs->{selected} = 'true' if $this->default eq $_;
		
		push @fields, $Data::Type::Field::XML->option( $attribs , $this->labels->{$_} || $_ );
	}

	my @html = $Data::Type::Field::XML->select( {

		id 		=> $this->id,
		class 	=> 'popup',

		name		=> $this->name,

		}, @fields
	);

return @html;
}

package Data::Type::Field::Form::Field::Radio;

Class::Maker::class { isa => [qw( Data::Type::Field::Form::Field Data::Type::Field::Form::Input)],

	public =>
	{
		int => [qw( default )],

		string => [qw(value)],
	},

	default => 
	{
		type => 'radio',
		
		value => 1,
	},
};

=head1

<input type="radio" name="PLASTIK" value="ON" checked />

=cut

sub to_html : method
{
	my $this = shift;

	my $href_attr =
	{
		id 		=> $this->id,
		class 	=> $this->type,

		type	=> $this->type,
		name	=> $this->name,
		value	=> $this->value,
	};

	$href_attr->{checked} = 'checked' if $this->default;

	my @html = $Data::Type::Field::XML->input( $href_attr );

return @html;
}

package Data::Type::Field::Form::Field::Textarea;

Class::Maker::class { isa => [qw( Data::Type::Field::Form::Field Data::Type::Field::Form::Input)],

	public =>
	{
		int => [qw( rows columns readonly )],

		string => [qw( default )],
	},

	default => 
	{
		type => 'textarea',
		
		rows => 10,
		
		columns => 50,
	},

	configure =>
	{
		explicit => 0,
	},
};

=head1

<textarea name="article.textarea" rows=10 cols=50>Haupttext blabla..</textarea>

=cut

sub to_html : method
{
	my $this = shift;

	my $href_attr =
	{
		id 		=> $this->id,
		class 	=> $this->type,

		name	=> $this->name,
		rows	=> $this->rows,
		cols	=> $this->columns,

		ONFOCUS	=> $this->js_onfocus,
	};

	$href_attr->{readonly} = 'readonly' if $this->readonly;

	my @html = $Data::Type::Field::XML->textarea( $href_attr, $this->default );

return @html;
}

package Data::Type::Field::Form::Field::Textfield;

Class::Maker::class { isa => [qw( Data::Type::Field::Form::Field Data::Type::Field::Form::Input)],

	public =>
	{
		int => [qw( size maxlength override )],

		string => [qw( default )],
	},

	default => 
	{
		type => 'text',
		
		override => 1,
		
		size => 50,
		
		maxlength => 80,
	},

	configure =>
	{
		explicit => 0,
	},
};

=head1

<input type="text" name="article.textfield" id=5 value="Ueberschrift" size="50" maxlength="80" ONFOCUS="if (this.value==this.defaultValue) this.select()" />

=cut

sub to_html : method
{
	my $this = shift;

	my $href_attr =
	{
		id 		=> $this->id,
		class 	=> $this->type,

		type		=> $this->type,
		name		=> $this->name,
		value		=> $this->default,
		size		=> $this->size,
		maxlength	=> $this->maxlength,

		ONFOCUS		=> $this->js_onfocus,
	};

	my @html = $Data::Type::Field::XML->input( $href_attr );

return @html;
}

package Data::Type::Field::Form::Field::Group::Radios;

Class::Maker::class { isa => [qw( Data::Type::Field::Form::Field )],

	public =>
	{
		int => [qw(rows columns)],

		hash => [qw(labels)],

		array => [qw(values rowheaders colheaders)],
	},

	default => 
	{
		rows => 2,
		
		columns => 2,
	},
};

sub to_html : method
{
	my $this = shift;

	die unless ref($this->rowheaders) eq 'ARRAY';

	my $table = new Data::Type::Field::Table( caption => $this->name );

	(my $head = new Data::Type::Field::Table::Row( title => 'Nr' ))->push(@{ $this->colheaders });

	push @{ $table->head }, $head;

	my @vals = @{ $this->values };

	my $col_cnt = @{ $this->colheaders } || 1;

	my $row_cnt=0;

	do
	{
		my $body = new Data::Type::Field::Table::Row( title => $row_cnt++ );

		foreach( @vals[0..$col_cnt-1] )
		{
			if( $_ )
			{
				$body->push( Data::Type::Field::Form::Label->new( text => $this->labels->{$_} || $_, position => [1,2], contains => Data::Type::Field::Form::Field::Radio->new( name => $this->name, value => $_ ) ) );
			}
		}

		push @{ $table->body }, $body;

		shift @vals for 0..$col_cnt-1;
	}
	while(@vals);

return ( $table->to_html(), "\n" );
}

package Data::Type::Field::Form::Field::Group::Checkboxes;

Class::Maker::class { isa => [qw( Data::Type::Field::Form::Field )],

	public =>
	{
		int => [qw(rows columns)],

		hash => [qw(labels)],

		array => [qw(values rowheaders colheaders)],
	},

	default => 
	{
		rows => 2,
		
		columns => 2,
	},
};

sub to_html : method
{
	my $this = shift;

	die unless ref($this->rowheaders) eq 'ARRAY';

	my $table = new Data::Type::Field::Table( caption => 'Checkbox Group' );

	(my $head = new Data::Type::Field::Table::Row( title => 'Nr' ))->push(@{ $this->colheaders });

	push @{ $table->head }, $head;

	my @vals = @{ $this->values };

	my $col_cnt = @{ $this->colheaders } || 1;

	my $row_cnt=0;

	do
	{
		my $body = new Data::Type::Field::Table::Row( title => $row_cnt++ );

		foreach( @vals[0..$col_cnt-1] )
		{
			if( $_ )
			{
				$body->push( Data::Type::Field::Form::Label->new( text => $this->labels->{$_} || $_, position => [1,2], contains => Data::Type::Field::Form::Field::Checkbox->new( name => $this->name, value => $_ ) ) );
			}
		}

		push @{ $table->body }, $body;

		shift @vals for 0..$col_cnt-1;

	}while(@vals);

return ( $table->to_html(), "\n" );
}

package Data::Type::Field::Form::Field::Group::Buttons;

Class::Maker::class { isa => [qw( Data::Type::Field::Combo )],
	
};

sub to_html : method
{
	my $this = shift;

		my @html;

        push @html, Data::Type::Field::Form::Field::Button->new( type => 'reset', name => 'Reset', default => 'Reset' )->to_html();

        push @html, Data::Type::Field::Form::Field::Button->new( type => 'submit', name => '.defaults', default => 'Default' )->to_html();

        push @html, Data::Type::Field::Form::Field::Button->new( type => 'submit', name => 'submit', default => 'Submit' )->to_html();

return @html;
}

=pod


=head1 CONTACT

Sourceforge L<http://sf.net/projects/datatype> is hosting a project dedicated to this module. And I enjoy receiving your comments/suggestion/reports also via L<http://rt.cpan.org> or L<http://testers.cpan.org>. 

=head1 AUTHOR

Murat Uenalan, <muenalan@cpan.org>


=cut
