
The command `12567834' yields the character strings which specifies how to 
enter the page number specification so that every printed paper contains four 
pages from the original PDF in sequential order. 

This is to avoid that, for a 8-page pdf file, the page numbering order
of the papers from a printer for the booklet printing is, usually,
1,2,7,8,3,4,5,6 not in 1,2,3,4,5,6,7.8. - By running a command sentence
`12345678 8' you get 1-2,5-8,3-4 that can easily be copy and pasted 
into the page number specification to the printing menu so that you 
get the printed paper to be folded into a booklet with a page numbering
in sequential order that is 1,2,3,4,5,6,7,8. You can specify any positive 
number instead of 8. 

When printing with Adobe Acrobat Reader, the page range input field has several limitations.
You must keep the input within 100 characters, and you cannot specify more than 26 comma-separated page numbers.
Therefore, consecutive pages should be indicated with hyphens, and the page range string should be made 
as long as possible—up to just under 100 characters—to allow for efficient printing in a single operation.
The printing will be split across multiple operations as needed.
Each of these page range strings will be displayed separated by line breaks.
This makes it possible to specify around 30 pages of the original PDF file in a single operation.

For convenience, an option `-P' is also provided to output strings that can be used with PDFtk.

To learn more about how it works, run the help option using 12567834 --help.

参照 : https://qiita.com/toramili/items/4f1583bea45f51662055
