package CAM::PDFTaxforms;

use 5.006;
use warnings;
use strict;
use parent 'CAM::PDF';

our $VERSION = '1.20';

=head1 NAME

CAM::PDFTaxforms - CAM::PDF wrapper to also allow editing of checkboxes (ie. for IRS Tax forms).

=head1 AUTHOR

Jim Turner C<< <https://metacpan.org/author/TURNERJW> >>.

This module is a wrapper around and a drop-in replacement for 
L<CAM::PDF>, by Chris Dolan.

=head1 ACKNOWLEDGMENTS

Thanks to Chris Dolan and everyone involved in developing and 
supporting CAM::PDF, on which this module is based and relies on.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010-2019 Jim Turner C<< <mailto:turnerjw784@yahoo.com> >>

This library is free software; you can redistribute it and/or modify it
under the same terms as CAM::PDF and Perl itself.

L<CAM::PDF>:

Copyright (c) 2002-2006 Clotho Advanced Media, Inc., L<http://www.clotho.com/>

Copyright (c) 2007-2008 Chris Dolan

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SYNOPSIS

    #!/usr/bin/perl -w

    use strict;
    use CAM::PDFTaxforms;
    my $pdf = CAM::PDFTaxforms->new('f1040.pdf') or die "Could not open PDF ($!)!";    
    my $page1 = $pdf->getPageContent(1);

    #DISPLAY THE LIST NAMES OF EDITABLE FIELDS:
    my @fieldnames = $pdf->getFormFieldList();
    print "--fields=".join('|',@fieldnames)."=\n";

    #UPDATE THE VALUES OF ONE OF THE FIELDS AND A COUPLE OF THE CHECKBOXES:
    $pdf->fillFormFields('fieldname1' => 'value1', 'fieldname2' => 'value2');

    #WRITE THE UPDATED PDF FORM TO A NEW FILE NAME:
    $pdf->cleanoutput('f1040_completed.pdf');

Many example programs are included in this distribution to do useful
tasks.  See the C<bin> subdirectory.

=head1 DESCRIPTION

This package is a wrapper for and creates a L<CAM::PDF> object.  The 
difference is that some method functions are overridden to fix some 
issues and add some new features, namely to better handle IRS tax 
forms, many of which have checkboxes, in addition to numeric and text 
fields.  Several other patches have also been applied, particularly 
those provided by CAM::PDF bugs #58144, #122890 and #125299.  
Otherwise, it should work well as a full drop-in replacement for 
CAM::PDF in the API.

CAM::PDF description:

This package reads and writes any document that conforms to the PDF
specification generously provided by Adobe at
L<http://partners.adobe.com/public/developer/pdf/index_reference.html>
(link last checked Oct 2005).

The file format through PDF 1.5 is well-supported, with the exception
of the "linearized" or "optimized" output format, which this module
can read but not write.  Many specific aspects of the document model
are not manipulable with this package (like fonts), but if the input
document is correctly written, then this module will preserve the
model integrity.

The PDF writing feature saves as PDF 1.4-compatible.  That means that
we cannot write compressed object streams.  The consequence is that
reading and then writing a PDF 1.5+ document may enlarge the resulting
file by a fair margin.

This library grants you some power over the PDF security model.  Note
that applications editing PDF documents via this library MUST respect
the security preferences of the document.  Any violation of this
respect is contrary to Adobe's intellectual property position, as
stated in the reference manual at the above URL.

Technical detail regarding corrupt PDFs: This library adheres strictly
to the PDF specification.  Adobe's Acrobat Reader is more lenient,
allowing some corrupted PDFs to be viewable.  Therefore, it is
possible that some PDFs may be readable by Acrobat that are illegible
to this library.  In particular, files which have had line endings
converted to or from DOS/Windows style (i.e. CR-NL) may be rendered
unusable even though Acrobat does not complain.  Future library
versions may relax the parser, but not yet.

This version is HACKED by Jim Turner 09/2010 to enable the fillFormFields() 
function to also modify checkboxes (primarily on IRS Tax forms).

=head1 EXAMPLES

See the I<example/> subdirectory in the source tree.  There is a sample 
blank 2018 official IRS Schedule B tax form and two programs:  
I<dof1040sb.pl>, which fills in the form using the sample input data 
text file I<f1040sb_inputs.txt>, and creates a filled in version of the 
form called I<f1040sb_out.pdf>.  The other program (I<test1040sb.pl>) 
can read the data filled in the filled in form created by the other 
program and displays it as output.

To run the programs, switch to the I<example/> subdirectory in the source 
tree and run them without arguments (ie. B<./dof1040sb.pl>).

To see the names of the fields and their current values in a PDF form, 
such as the aforementioned tax form, run the included program, ie:  
I<listpdffields2.pl -d f1040sb_out.pdf>.

=head1 API

=head2 Functions intended to be used externally

 $self = CAM::PDFTaxforms->new(content | filename | '-')
 $self->toPDF()
 $self->needsSave()
 $self->save()
 $self->cleansave()
 $self->output(filename | '-')
 $self->cleanoutput(filename | '-')
 $self->previousRevision()
 $self->allRevisions()
 $self->preserveOrder()
 $self->appendObject(olddoc, oldnum, [follow=(1|0)])
 $self->replaceObject(newnum, olddoc, oldnum, [follow=(1|0)])
    (olddoc can be undef in the above for adding new objects)
 $self->numPages()
 $self->getPageText(pagenum)
 $self->getPageDimensions(pagenum)
 $self->getPageContent(pagenum)
 $self->setPageContent(pagenum, content)
 $self->appendPageContent(pagenum, content)
 $self->deletePage(pagenum)
 $self->deletePages(pagenum, pagenum, ...)
 $self->extractPages(pagenum, pagenum, ...)
 $self->appendPDF(CAM::PDF object)
 $self->prependPDF(CAM::PDF object)
 $self->wrapString(string, width, fontsize, page, fontlabel)
 $self->getFontNames(pagenum)
 $self->addFont(page, fontname, fontlabel, [fontmetrics])
 $self->deEmbedFont(page, fontname, [newfontname])
 $self->deEmbedFontByBaseName(page, basename, [newfont])
 $self->getPrefs()
 $self->setPrefs()
 $self->canPrint()
 $self->canModify()
 $self->canCopy()
 $self->canAdd()
 $self->getFormFieldList()
 $self->fillFormFields(fieldname, value, [fieldname, value, ...])
   or $self->fillFormFields(%values)
 $self->clearFormFieldTriggers(fieldname, fieldname, ...)

Note: 'clean' as in cleansave() and cleanobject() means write a fresh
PDF document.  The alternative (e.g. save()) reuses the existing doc
and just appends to it.  Also note that 'clean' functions sort the
objects numerically.  If you prefer that the new PDF docs more closely
resemble the old ones, call preserveOrder() before cleansave() or
cleanobject().

=head2 For additional methods and functions, see the L<CAM::PDF> documentation.

=head1 METHODS

=over

=item $doc = CAM::PDFTaxforms->new($content)

=item $doc = CAM::PDFTaxforms->new($ownerpass, $userpass)

=item $doc = CAM::PDFTaxforms->new($content, $ownerpass, $userpass, $prompt)

=item $doc = CAM::PDFTaxforms->new($content, $ownerpass, $userpass, $options)

Instantiate a new CAM::PDFTaxforms object.  C<$content> can be a document 
in a string, a filename, or '-'.  The latter indicates that the document
should be read from standard input.  If the document is password
protected, the passwords should be passed as additional arguments.  If
they are not known, a boolean C<$prompt> argument allows the programmer to
suggest that the constructor prompt the user for a password.  This is
rudimentary prompting: passwords are in the clear on the console.

This constructor takes an optional final argument which is a hash
reference.  This hash can contain any of the following optional
parameters:

=over

=item prompt_for_password => $boolean

This is the same as the C<$prompt> argument described above.

=item fault_tolerant => $boolean

This flag causes the instance to be more lenient when reading the
input PDF.  Currently, this only affects PDFs which cannot be
successfully decrypted.

=back

=item $hashref = $doc->getFieldValue('fieldname1' [, fieldname2, ... fieldnameN ])

(CAM::PDFTaxforms only, not available in CAM::PDF)

Fetches the corresponding current values for each field name in the 
argument list.  Returns a reference to a hash containing the field 
names as keys and the corresponding values.  If a field does not 
exist or does not contain a value, an empty string is returned in 
the hash as it's value.  If called in array / hash context, then 
a list of field names and values in the order (fieldname1, value1, 
fieldname2, value2, ... fieldnameN valueN) is returned.

=cut

sub getFieldValue   #JWT:NEW FUNCTION ADDED 20100921 TO RETURN CORRECT VALUES 
                    #FOR EACH FIELD WHETHER IT'S A TEXT FIELD OR A CHECKBOX:
{
   my $self = shift;
   my @fieldNames = @_;

   my ($objnode, $propdict, $dict, $fieldType, $fieldHashRef);
LOOP1:	 foreach my $fieldName (@fieldNames)
   {
      $objnode = $self->getFormField($fieldName);
      $fieldHashRef->{$fieldName} = undef;
      next LOOP1  unless ($objnode);

      # This read-only dict includes inherited properties
      my $propdict = $self->getFormFieldDict($objnode);

      # This read-write dict does not include inherited properties
      my $dict = $self->getValue($objnode);

      if ($propdict->{FT} && $self->getValue($propdict->{FT}) =~ /^Btn$/o) {
         $fieldHashRef->{$fieldName} = (defined $dict->{AS}->{value})
               ? $dict->{AS}->{value} : $dict->{V}->{value};
      } else {
      	  $fieldHashRef->{$fieldName} = $dict->{V}->{value};
      }
   }
   return $fieldHashRef  unless (wantarray);  #RETURN HASHREF IN SCALAR CONTEXT.
   my @fieldValues;
   foreach my $fieldName (@fieldNames)   #BUILD ARRAY FROM HASH TO RETURN IN ARRAY CONTEXT:
   {
      push (@fieldValues, $fieldName, $fieldHashRef->{$fieldName});
   }
   return @fieldValues;
}

=item $doc->fillFormFields($name => $value, ...)

=item $doc->fillFormFields($opts_hash, $name => $value, ...)

Set the default values of PDF form fields.  The name should be the
full hierarchical name of the field as output by the
getFormFieldList() function.  The argument list can be a hash if you
like.  A simple way to use this function is something like this:

    my %fields = (fname => 'John', lname => 'Smith', state => 'WI');
    $field{zip} = 53703;
    $self->fillFormFields(%fields);

NOTE:  For checkbox fields specify any value that is I<false> in Perl 
(ie. 0, '', or I<undef>), or any of the strings:  'Off', 'No', or 
'Unchecked' (case insensitive) to un-check a checkbox, or any other 
value that is I<true> in Perl to check it.  Checkbox fields are only 
supported by CAM::PDFTaxforms and was the original reason for 
creating it.

If the first argument is a hash reference, it is interpreted as
options for how to render the filled data:

=over

=item background_color =E<lt> 'none' | $gray | [$r, $g, $b]

Specify the background color for the text field.

=back

=cut

sub fillFormFields  ## no critic(Subroutines::ProhibitExcessComplexity, Unpack)
{
   my $self = shift;
   my $opts = ref $_[0] ? shift : {};
   my @list = (@_);

   my %opts = (
      background_color => 1,
      %{$opts},
   );

   my $filled = 0;
LOOP1:   while (@list > 0)
   {
      my $key = shift @list;
      my $value = shift @list;

      $value = q{}  unless (defined $value);
      next if (!$key || ref($key));

      my $objnode = $self->getFormField($key);
      next unless ($objnode);

      my $objnum = $objnode->{objnum};
      my $gennum = $objnode->{gennum};

      # This read-only dict includes inherited properties
      my $propdict = $self->getFormFieldDict($objnode);

      # This read-write dict does not include inherited properties
      my $dict = $self->getValue($objnode);
      $dict->{V} = CAM::PDF::Node->new('string', $value, $objnum, $gennum);

      if ($propdict->{FT} && $self->getValue($propdict->{FT}) =~ /^(Tx|Btn)$/o)  # Is it a text field?
      {
         my $fieldType = $1;  #JWT:ADDED NEXT 6 TO ALLOW SETTING OF CHECKBOX BUTTONS (VALUE MUST BE EITHER "Yes" or "Off"!:
         if ($fieldType eq 'Btn')   #WE'RE A BUTTON (CHECKBOX OR RADIO)
         {
            my @kidnames = $self->getFormFieldList($key);
            if (@kidnames > 0) {    #WE HAVE KIDS, SO WE'RE A RADIO-BUTTON:
               local * setRadioButtonKids = sub {
               	  my ($indx, $vindx) = @_;
               	  my $objnode = $self->getFormField($kidnames[$indx]);
               	  return  unless ($objnode);
               	  my $dict = $self->getValue($objnode);
                  if ($indx == $vindx) {
                     $dict->{AS}->{value} = $value;
                  } else {
                  	  $dict->{AS}->{value} = 'Off';
                  }
                  return;
               };

               $dict->{V}->{value} = ($value > 0) ? $value : 'Off';
               my $vindx = $value - 1;
               for (my $i=0;$i<=$#kidnames;$i++) {
               	  &setRadioButtonKids($i, $vindx);
               }
            } else {                #WE'RE A SINGLE CHECKBOX:
            	  if (!$value || $value =~ /^(?:Off|No|Unchecked)$/io) {  #USER WANTS IT UNCHECKED:
            	     $dict->{AS}->{value} = 'Off';
            	     $dict->{V}->{value} = 'Off';
            	  } else {  #USER WANTS IT CHECKED:
            	     my ($onValue) = defined($dict->{AP}->{value}->{N}->{value}
            	           && ref($dict->{AP}->{value}->{N}->{value}) =~ /^HASH/) 
            	        ? keys(%{$dict->{AP}->{value}->{N}->{value}}) : ('Yes');
            	     $dict->{AS}->{value} = $onValue;
            	     $dict->{V}->{value} = $onValue;
            	  }
            }
            $filled++;
            next LOOP1;
         }
         else  #WE'RE A TEXT FIELD:
         {
         	  $dict->{V}->{value} = $value;
         }

         # Set up display of form value
         $dict->{AP} = CAM::PDF::Node->new('dictionary', {}, $objnum, $gennum)  unless ($dict->{AP});
         unless ($dict->{AP}->{value}->{N})
         {
            my $newobj = CAM::PDF::Node->new('object',
                                            CAM::PDF::Node->new('dictionary',{}),
                                            );
            my $num = $self->appendObject(undef, $newobj, 0);
            $dict->{AP}->{value}->{N} = CAM::PDF::Node->new('reference', $num, $objnum, $gennum);
         }
         my $formobj = ($self->dereference($fieldType eq 'Btn' && defined($dict->{AS}->{value})
               && $dict->{AS}->{value} 
               && defined($dict->{AP}->{value}->{N}->{value}->{$dict->{AS}->{value}}->{value})
                  ? $dict->{AP}->{value}->{N}->{value}->{$dict->{AS}->{value}}->{value}
                  : $dict->{AP}->{value}->{N}->{value}));
         my $formonum = $formobj->{objnum};
         my $formgnum = $formobj->{gennum};
         my $formdict = $self->getValue($formobj);

         $formdict->{Subtype} = CAM::PDF::Node->new('label', 'Form', $formonum, $formgnum)
               unless ($formdict->{Subtype});

         my @rect = (0,0,0,0);
         if ($dict->{Rect})
         {
            ## no critic(Bangs::ProhibitNumberedNames)
            my $r = $self->getValue($dict->{Rect});
            my ($x1, $y1, $x2, $y2) = @{$r};
            @rect = (
               $self->getValue($x1),
               $self->getValue($y1),
               $self->getValue($x2),
               $self->getValue($y2),
            );
         }
         my $dx = $rect[2]-$rect[0];
         my $dy = $rect[3]-$rect[1];
         unless ($formdict->{BBox})
         {
            $formdict->{BBox} = CAM::PDF::Node->new('array',
               [
                  CAM::PDF::Node->new('number', 0, $formonum, $formgnum),
                  CAM::PDF::Node->new('number', 0, $formonum, $formgnum),
                  CAM::PDF::Node->new('number', $dx, $formonum, $formgnum),
                  CAM::PDF::Node->new('number', $dy, $formonum, $formgnum),
               ],
               $formonum, $formgnum);
         }
         my $text = $value;
         $text =~ s/ \r\n? /\n/gxmso;
         $text =~ s/ \n+\z //xmso;

         my @rsrcs;
         my $fontmetrics = 0;
         my $fontname    = q{};
         my $fontsize    = 0;
         my $da          = q{};
         my $tl          = q{};
         #JWT:CHGD TO NEXT PER BUG#122890: my $border      = 2;
         my $border      = 1;
         my $tx          = $border;
         #JWT:CHGD TO NEXT PER BUG#122890: my $ty          = $border + 2;
         my $ty          = $border + 1;
         my $stringwidth;
         if ($propdict->{DA}) {
            $da = $self->getValue($propdict->{DA});

            # Try to pull out all of the resources used in the text object
            @rsrcs = ($da =~ m{ /([^\s<>/\[\]()]+) }gxmso);

            # Try to pull out the font size, if any.  If more than
            # one, pick the last one.  Font commands look like:
            # "/<fontname> <size> Tf"
            #JWT: CHGD. TO NEXT (BUG#58144 PATCH): if ($da =~ m{ \s*/(\w+)\s+(\d+)\s+Tf.*? \z }xms)
            if ($da =~ m{ \s*/([\w-]+)\s+([.\d]+)\s+Tf.*? \z }xmso)
            {
               $fontname = $1;
               $fontsize = $2;
               if ($fontname)
               {
                  if ($propdict->{DR})
                  {
                     my $dr = $self->getValue($propdict->{DR});
                     $fontmetrics = $self->getFontMetrics($dr, $fontname);
                  }
                  #print STDERR "Didn't get font\n" if (!$fontmetrics);
               }
            }
         }

         my %flags = (
            Justify => 'left',
         );
         if ($propdict->{Ff})
         {
            # Just decode the ones we actually care about
            # PDF ref, 3rd ed pp 532,543
            my $ff = $self->getValue($propdict->{Ff});
            my @flags = split m//xms, unpack 'b*', pack 'V', $ff;
            $flags{ReadOnly}        = $flags[0];
            $flags{Required}        = $flags[1];
            $flags{NoExport}        = $flags[2];
            $flags{Multiline}       = $flags[12];
            $flags{Password}        = $flags[13];
            $flags{FileSelect}      = $flags[20];
            $flags{DoNotSpellCheck} = $flags[22];
            $flags{DoNotScroll}     = $flags[23];
         }
         if ($propdict->{Q})
         {
            my $q = $self->getValue($propdict->{Q}) || 0;
            $flags{Justify} = $q==2 ? 'right' : ($q==1 ? 'center' : 'left');
         }

         # The order of the following sections is important!
         $text =~ s/ [^\n] /*/gxms  if ($flags{Password});  # Asterisks for password characters

         if ($fontmetrics && ! $fontsize)
         {
            # Fix autoscale fonts
            $stringwidth = 0;
            my $lines = 0;
            for my $line (split /\n/xmso, $text)  # trailing null strings omitted
            {
               $lines++;
               my $w = $self->getStringWidth($fontmetrics, $line);
               $stringwidth = $w  if ($w && $w > $stringwidth);
            }
            $lines ||= 1;
            # Initial guess
            $fontsize = ($dy - 2 * $border) / ($lines * 1.5);
            my $fontwidth = $fontsize * $stringwidth;
            my $maxwidth = $dx - 2 * $border;
            $fontsize *= $maxwidth / $fontwidth  if ($fontwidth > $maxwidth);
            $da =~ s/ \/$fontname\s+0\s+Tf\b /\/$fontname $fontsize Tf/gxms;
         }
         if ($fontsize)
         {
            # This formula is TOTALLY empirical.  It's probably wrong.
#           #JWT:CHGD. TO NEXT:  $ty = $border + 2 + (9 - $fontsize) * 0.4;
            $ty = $border + 2 + (5 - $fontsize) * 0.4;
         }


         # escape characters
         $text = $self->writeString($text);

         if ($flags{Multiline})
         {
            # TODO: wrap the field with wrapString()??
            # Shawn Dawson of Silent Solutions pointed out that this does not auto-wrap the input text

            my $linebreaks = $text =~ s/ \\n /\) Tj T* \(/gxms;

            # Total guess work:
            # line height is either 150% of fontsize or thrice
            # the corner offset
            $tl = $fontsize ? $fontsize * 1.5 : $ty * 3;

            # Bottom aligned
            #$ty += $linebreaks * $tl;
            # Top aligned
            $ty = $dy - $border - $tl;
            warn 'Justified text not supported for multiline fields'  if ($flags{Justify} ne 'left');
            $tl .= ' TL';
         }
         else
         {
            #JWT: CHGD. TO NEXT (BUG#58144 PATCH): if ($flags{Justify} ne 'left' && $fontmetrics)
            if ($flags{Justify} ne 'left')
            {
               #JWT: CHGD. TO NEXT 8: my $width = $stringwidth || $self->getStringWidth($fontmetrics, $text);
               my $width;
               if ($stringwidth || $fontmetrics) {
                  #JWT:CHGD TO NEXT PER BUG#122890: $width = $self->getStringWidth($fontmetrics, $text);
                  $width = $self->getStringWidth($fontmetrics, (substr $text, 1, (length $text)-2));
               } else {  #JWT: NO FONT METRICS, SO HAVE TO GUESS WIDTH:
               	  $width = (length($text)-1) * 0.57;  #JWT:FIXME (HACK) FOR RIGHT-JUSTIFYING STANDARD SIZE 8 NUMERIC FONT.
                  my $commas = $text;
                  $width -= 0.29  while ($commas =~ s/\,//o);  #JWT:FIXME (HACK) FUDGE FOR WIDTH OF COMMAS (SMALLER THAN DIGITS)
               }
               my $diff = $dx - $width * $fontsize;
               $diff = 0  if ($diff < 0);  #JWT:ADDED.

               if ($flags{Justify} eq 'center')
               {
                  $text = ($diff/2)." 0 Td $text";
               }
               elsif ($flags{Justify} eq 'right')
               {
                  $text = "$diff 0 Td $text";
               }
            }
         }

         # Move text from lower left corner of form field
         my $tm = "1 0 0 1 $tx $ty Tm ";

         # if not 'none', draw a background as a filled rectangle of solid color
         my $background_color
               = $opts{background_color} eq 'none' ? q{}
               : ref $opts{background_color}       ? "@{$opts{background_color}} rgb"
                     : "$opts{background_color} g";
         my $background = $background_color ? "$background_color 0 0 $dx $dy re f" : q{};

         $text =  "$tl $da $tm $text Tj";
         $text = "$background /Tx BMC q 1 1 ".($dx-$border).q{ }.($dy-$border)." re W n BT $text ET Q EMC";
         unless ($fieldType eq 'Btn')  #JWT:ADDED CONDITION:
         {
            $formdict->{Length} = CAM::PDF::Node->new('number', length($text), $formonum, $formgnum);
            # JWT:NEXT 3 ADDED PER BUG#125299 PATCH:
            $formdict->{StreamData} = CAM::PDF::Node->new('stream', $text, $formonum, $formgnum);
            delete $formdict->{ Filter };
            $self-> encodeObject( $formonum, 'FlateDecode' );
         }

         if (@rsrcs > 0) {
            $formdict->{Resources} = CAM::PDF::Node->new('dictionary', {}, $formonum, $formgnum)
                  unless ($formdict->{Resources});

            my $rdict = $self->getValue($formdict->{Resources});
            unless ($rdict->{ProcSet})
            {
               $rdict->{ProcSet} = CAM::PDF::Node->new('array',
                  [
                     CAM::PDF::Node->new('label', 'PDF', $formonum, $formgnum),
                     CAM::PDF::Node->new('label', 'Text', $formonum, $formgnum),
                  ],
                  $formonum, $formgnum);
            }
            $rdict->{Font} = CAM::PDF::Node->new('dictionary', {}, $formonum, $formgnum)
                  unless ($rdict->{Font});

            my $fdict = $self->getValue($rdict->{Font});

            # Search out font resources.  This is a total kluge.
            # TODO: the right way to do this is to look for the DR
            # attribute in the form element or it's ancestors.
            for my $font (@rsrcs)
            {
               #JWT: CHGD. TO NEXT 11 (BUG#58144 PATCH): my $fobj = $self->dereference("/$font", 'All');
               #JWT: CHGD. TO NEXT 11 (BUG#58144 PATCH): if (!$fobj)
               my $root = $self->getRootDict()->{AcroForm};
               my $ifdict = $self->getValue($root);
               unless (exists $ifdict->{DR})
               {
                  #JWT:die "Could not find resource /$font while preparing form field $key\n";
                  warn "Could not find resource1 /$font while preparing form field $key\n";
               }
               my $dr = $self->getValue($ifdict->{DR});
               my $fobjnum = $dr->{Font}->{value}->{$font}->{value};

               unless ($fobjnum)
               {
                  #JWT:die "Could not find resource /$font while preparing form field $key\n";
                  warn "Could not find resource2 /$font while preparing form field $key\n";
               }
               #JWT: CHGD. TO NEXT (BUG#58144 PATCH): $fdict->{$font} = CAM::PDF::Node->new('reference', $fobj->{objnum}, $formonum, $formgnum);
               $fdict->{$font} = CAM::PDF::Node->new('reference', $fobjnum, $formonum, $formgnum); 
            }
         }
      }
      $filled++;
   }

   return $filled;
}

=item $doc->getFormFieldList()

Return an array of the names of all of the PDF form fields.  The names
are the full hierarchical names constructed as explained in the PDF
reference manual.  These names are useful for the fillFormFields()
function.

=cut

sub getFormFieldList
{
   my $self = shift;
   my $parentname = shift;  # very optional

   my $prefix = (defined $parentname ? $parentname . q{.} : q{});

   my $kidlist;
   if (defined $parentname && $parentname ne q{})
   {
      my $parent = $self->getFormField($parentname);
      return  unless ($parent);
      my $dict = $self->getValue($parent);
      return  unless (exists $dict->{Kids});
      $kidlist = $self->getValue($dict->{Kids});
   }
   else
   {
      my $root = $self->getRootDict()->{AcroForm};
      return  unless ($root);
      my $parent = $self->getValue($root);
      return  unless (exists $parent->{Fields});
      $kidlist = $self->getValue($parent->{Fields});
   }

   my @list;
   my $nonamecnt = '0';
   for my $kid (@{$kidlist})
   {
      if ((! ref $kid) || (ref $kid) ne 'CAM::PDF::Node' || $kid->{type} ne 'reference')
      {
         die "Expected a reference as the form child of '$parentname'\n";
      }
      my $objnode = $self->dereference($kid->{value});
      my $dict = $self->getValue($objnode);
      my $name = "(no name$nonamecnt)";  # assume the worst
      ++$nonamecnt;
      $name = $self->getValue($dict->{T})  if (exists $dict->{T});
      $name = $prefix . $name;
      $name =~ s/\x00//gso;   #JWT:HANDLE IRS'S FSCKED-UP HIGH-ASCII FIELD NAMES!
      push @list, $name;
      push @list, $prefix . $self->getValue($dict->{TU}) . ' (alternate name)'  if (exists $dict->{TU});
      $self->{formcache}->{$name} = $objnode;
      my @kidnames = $self->getFormFieldList($name);
      if (@kidnames > 0)
      {
         #push @list, 'descend...';
         push @list, @kidnames;
         #push @list, 'ascend...';
      }
   }
   return @list;
}

=item $doc->getFormField($name)

I<For INTERNAL use>

Return the object containing the form field definition for the
specified field name.  C<$name> can be either the full name or the
"short/alternate" name.

=cut

sub getFormField
{
   my $self = shift;
   my $fieldname = shift;

   return  unless (defined $fieldname);

   unless (exists $self->{formcache}->{$fieldname})
   {
      my $kidlist;
      my $parent;
      if ($fieldname =~ m/ [.] /xms)
      {
         my $parentname;
         #JWT: CHGD. TO NEXT (BUG#58144 PATCH): if ($fieldname =~ s/ \A(.*)[.]([.]+)\z /$2/xms)
         $parentname = $1  if ($fieldname =~ s/ \A(.*)[.]([^.]+)\z /$2/xms);
         return  unless ($parentname);
         $parent = $self->getFormField($parentname);
         return  unless ($parent);
         my $dict = $self->getValue($parent);
         return  unless (exists $dict->{Kids});
         $kidlist = $self->getValue($dict->{Kids});
      }
      else
      {
         my $root = $self->getRootDict()->{AcroForm};
         return  unless ($root);
         $parent = $self->dereference($root->{value});
         return  unless ($parent);
         my $dict = $self->getValue($parent);
         return  unless (exists $dict->{Fields});
         $kidlist = $self->getValue($dict->{Fields});
      }

      $self->{formcache}->{$fieldname} = undef;  # assume the worst...
      for my $kid (@{$kidlist})
      {
         my $objnode = $self->dereference($kid->{value});
         $objnode->{formparent} = $parent;
         my $dict = $self->getValue($objnode);
         $self->{formcache}->{$self->getValue($dict->{T})} = $objnode  if (exists $dict->{T});
         $self->{formcache}->{$self->getValue($dict->{TU})} = $objnode  if (exists $dict->{TU});
      }
   }

   return $self->{formcache}->{$fieldname};
}

=item $doc->writeAny($node)

Returns the serialization of the specified node.  This handles all
Node types, including object Nodes.

=cut

sub writeAny
{
   my $self = shift;
   my $objnode = shift;

   die 'Not a ref'  unless (ref $objnode);

   my $key = $objnode->{type};

   return 1  unless (defined($key) && $key);  #JWT:ADDED!

   my $val = $objnode->{value};
   my $objnum = $objnode->{objnum};
   my $gennum = $objnode->{gennum};

   return $key eq 'string'     ? $self->writeString($self->{crypt}->encrypt($self, $val, $objnum, $gennum))
        : $key eq 'hexstring'  ? '<' . (unpack 'H*', $self->{crypt}->encrypt($self, $val, $objnum, $gennum)) . '>'
        : $key eq 'number'     ? "$val"
        : $key eq 'reference'  ? "$val 0 R" # TODO: lookup the gennum and use it instead of 0 (?)
        : $key eq 'boolean'    ? $val
        : $key eq 'null'       ? 'null'
        : $key eq 'label'      ? "/$val"
        : $key eq 'array'      ? $self->_writeArray($objnode)
        : $key eq 'dictionary' ? $self->_writeDictionary($objnode)
        : $key eq 'object'     ? $self->_writeObject($objnode)
#JWT:CHGD. TO NEXT (TO PREVENT DEATH!):        : die "Unknown key '$key' in writeAny (objnum ".($objnum||'<none>').")\n";
        : warn "Unknown key '$key' (value=$val= objnum=$objnum gen=$gennum) in writeAny (objnum ".($objnum||'<none>').")\n";
}

1;

__END__

=back

=head1 SCRIPTS

CAM::PDF includes a number of handy utility scripts, installed in 
the users local/bin path, but we add a modified version of their 
I<listpdffields.pl> utility that is called B<listpdffields2.pl> 
which adds a -d (--data) option for displaying the names of all the 
fields found in a PDF form, along with their corresponding current 
values (if any).  

=over

=item B<listpdffiles2.pl> [-dhsvV] I<pdfformfile.pdf>

The general format is:

listpdffiles2.pl -d I<pdfformfile.pdf>

=back

=head1 COMPATIBILITY

This library was primarily developed against the 3rd edition of the
reference (PDF v1.4) with several important updates from 4th edition
(PDF v1.5).  This library focuses most deeply on PDF v1.2 features.
Nonetheless, it should be forward and backward compatible in the
majority of cases.

=head1 PERFORMANCE

This module is written with good speed and flexibility in mind, often
at the expense of memory consumption.  Entire PDF documents are
typically slurped into RAM.  As an example, simply calling
C<new('PDFReference15_v15.pdf')> (the 13.5 MB Adobe PDF Reference V1.5
document) pushes Perl to consume 89 MB of RAM on my development
machine.

=head1 DEPENDS

L<CAM::PDF>, L<Text::PDF>, L<Crypt::RC4>, L<Digest::MD5>

=head1 KEYWORDS

pdf taxforms

=head1 KNOWN BUGS / TODO

1)  Checkboxes / radio buttons set programatically to "CHECKED" by 
CAM::PDFTaxforms ARE checked, and shown as so in the form, but 
B<evince>, and perhaps Acrobat(tm) form editor don't seem to 
consider them checked the first time a user clicks on them to 
uncheck them, requiring a second click.  This can be especially 
disconcerting to the user for radio-buttons as it is possible to click 
a second button in the group checking it, but the originally-checked 
button is NOT automatically unchecked.  I need to somehow FIX this, 
but have so far been unable to do so (as of v1.1 - sorry!), so please 
don't file a bug on this UNLESS you have a PATCH for either me OR 
CAM::PDF itself!

2)  CAM::PDF is used under the hood for most of the actual work, and 
has many open bugs / issues (see:  L<https://rt.cpan.org/Public/Dist/Display.html?Name=CAM-PDF>), 
so, except for the patched ones mentioned in the B<DESCRIPTION> section above, 
those issues remain unfixed here as well!  Therefore, check if your issue 
works if using standard B<CAM::PDF> first before filing a new bug here 
(or unless it involves a specific CAM::PDFTextforms feature, or you have 
a patch, in which case you're likely to get it merged here sooner!).

=head1 SEE ALSO

L<CAM::PDF> (Obviously) as this module is a wrapper around it (and 
requires it as a prerequisite).  Also see the docs there for all the 
other methods and features available to CAM::PDFTaxforms (it's NOT 
just for IRS tax forms)!

There are several other PDF modules on CPAN.  Below is a brief
description of a few of them.  If these comments are out of date,
please inform me.

=over

=item L<PDF::API2>

As of v0.46.003, LGPL license.

This is the leading PDF library, in my opinion.

Excellent text and font support.  This is the highest level library of
the bunch, and is the most complete implementation of the Adobe PDF
spec.  The author is amazingly responsive and patient.

=item L<Text::PDF>

As of v0.25, Artistic license.

Excellent compression support (CAM::PDF cribs off this Text::PDF
feature).  This has not been developed since 2003.

=item L<PDF::Reuse>

As of v0.32, Artistic/GPL license, like Perl itself.

This library is not object oriented, so it can only process one PDF at
a time, while storing all data in global variables.  I'm not fond of
it, but it's quite popular, so don't take my word for it!

=back

Additionally, PDFLib is a commercial package not on CPAN
(L<www.pdflib.com>).  It is a C-based library with a Perl interface.
It is designed for PDF creation, not for reuse.

=cut
