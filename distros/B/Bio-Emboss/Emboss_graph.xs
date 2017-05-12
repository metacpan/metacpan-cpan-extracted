#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_graph		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajgraph.c: automatically generated

void
ajGraphSetDevice (thys)
       const AjPGraph thys

void
ajGraphSetName (thys)
       const AjPGraph thys

void
ajGraphLabel (x, y, title, subtitle)
       const char* x
       const char* y
       const char* title
       const char* subtitle

void
ajGraphSetPenWidth (width)
       float width

void
ajGraphOpenPlot (thys, numofsets)
       AjPGraph thys
       ajint numofsets
    OUTPUT:
       thys

void
ajGraphOpenWin (thys, xmin, xmax, ymin, ymax)
       AjPGraph thys
       float xmin
       float xmax
       float ymin
       float ymax
    OUTPUT:
       thys

void
ajGraphNewPage (thys, resetdefaults)
       AjPGraph thys
       AjBool resetdefaults
    OUTPUT:
       thys

void
ajGraphCloseWin ()

void
ajGraphOpen (thys, xmin, xmax, ymin, ymax, flags)
       AjPGraph thys
       PLFLT xmin
       PLFLT xmax
       PLFLT ymin
       PLFLT ymax
       ajint flags
    OUTPUT:
       thys

void
ajGraphLabelYRight (text)
       const char* text

void
ajGraphClose ()

AjBool
ajGraphSet (thys, type)
       AjPGraph thys
       const AjPStr type
    OUTPUT:
       RETVAL

AjBool
ajGraphxySet (thys, type)
       AjPGraph thys
       const AjPStr type
    OUTPUT:
       RETVAL

void
ajGraphDumpDevices ()

void
ajGraphTrace (thys)
       const AjPGraph thys

void
ajGraphPlpDataTrace (thys)
       const AjPGraphPlpData thys

void
ajGraphCircle (xcentre, ycentre, radius)
       PLFLT xcentre
       PLFLT ycentre
       float radius

void
ajGraphPolyFill (n, x, y)
       ajint n
       PLFLT * x
       PLFLT * y

void
ajGraphPoly (n, x, y)
       ajint n
       PLFLT * x
       PLFLT * y

void
ajGraphTriFill (xx1, yy1, xx2, yy2, x3, y3)
       PLFLT xx1
       PLFLT yy1
       PLFLT xx2
       PLFLT yy2
       PLFLT x3
       PLFLT y3

void
ajGraphTri (xx1, yy1, xx2, yy2, x3, y3)
       PLFLT xx1
       PLFLT yy1
       PLFLT xx2
       PLFLT yy2
       PLFLT x3
       PLFLT y3

void
ajGraphDiaFill (xx0, yy0, size)
       PLFLT xx0
       PLFLT yy0
       PLFLT size

void
ajGraphDia (xx0, yy0, size)
       PLFLT xx0
       PLFLT yy0
       PLFLT size

void
ajGraphBoxFill (xx0, yy0, size)
       PLFLT xx0
       PLFLT yy0
       PLFLT size

void
ajGraphBox (xx0, yy0, size)
       PLFLT xx0
       PLFLT yy0
       PLFLT size

void
ajGraphRectFill (xx0, yy0, xx1, yy1)
       PLFLT xx0
       PLFLT yy0
       PLFLT xx1
       PLFLT yy1

void
ajGraphRect (xx0, yy0, xx1, yy1)
       PLFLT xx0
       PLFLT yy0
       PLFLT xx1
       PLFLT yy1

void
ajGraphSetBackWhite ()

void
ajGraphSetBackBlack ()

void
ajGraphColourBack ()

void
ajGraphColourFore ()

ajint
ajGraphSetFore (colour)
       ajint colour
    OUTPUT:
       RETVAL

ajint
ajGraphCheckColour (colour)
       const AjPStr colour
    OUTPUT:
       RETVAL

ajint*
ajGraphGetBaseColour ()
    OUTPUT:
       RETVAL

ajint*
ajGraphGetBaseColourProt (codes)
       const AjPStr codes
    OUTPUT:
       RETVAL

ajint*
ajGraphGetBaseColourNuc (codes)
       const AjPStr codes
    OUTPUT:
       RETVAL

void
ajGraphGetCharSize (defheight, currentheight)
       float & defheight
       float & currentheight
    OUTPUT:
       defheight
       currentheight

void
ajGraphGetOut (xp, yp, xleng, yleng, xoff, yoff)
       float & xp
       float & yp
       ajint & xleng
       ajint & yleng
       ajint & xoff
       ajint & yoff
    OUTPUT:
       xp
       yp
       xleng
       yleng
       xoff
       yoff

void
ajGraphSetOri (ori)
       ajint ori

void
ajGraphPlenv (xmin, xmax, ymin, ymax, flags)
       float xmin
       float xmax
       float ymin
       float ymax
       ajint flags

ajint
ajGraphGetColour ()
    OUTPUT:
       RETVAL

const AjPStr
ajGraphGetSubTitle (thys)
       const AjPGraph thys
    OUTPUT:
       RETVAL

const char*
ajGraphGetSubTitleC (thys)
       const AjPGraph thys
    OUTPUT:
       RETVAL

const AjPStr
ajGraphGetTitle (thys)
       const AjPGraph thys
    OUTPUT:
       RETVAL

const char*
ajGraphGetTitleC (thys)
       const AjPGraph thys
    OUTPUT:
       RETVAL

const AjPStr
ajGraphGetXTitle (thys)
       const AjPGraph thys
    OUTPUT:
       RETVAL

const char*
ajGraphGetXTitleC (thys)
       const AjPGraph thys
    OUTPUT:
       RETVAL

const AjPStr
ajGraphGetYTitle (thys)
       const AjPGraph thys
    OUTPUT:
       RETVAL

const char*
ajGraphGetYTitleC (thys)
       const AjPGraph thys
    OUTPUT:
       RETVAL

ajint
ajGraphSetLineStyle (style)
       ajint style
    OUTPUT:
       RETVAL

ajint
ajGraphSetFillPat (style)
       ajint style
    OUTPUT:
       RETVAL

float
ajGraphSetCharScale (scale)
       float scale
    OUTPUT:
       RETVAL

void
ajGraphLine (xx1, yy1, xx2, yy2)
       PLFLT xx1
       PLFLT yy1
       PLFLT xx2
       PLFLT yy2

void
ajGraphLines (xx1, yy1, xx2, yy2, numoflines)
       PLFLT& xx1
       PLFLT& yy1
       PLFLT& xx2
       PLFLT& yy2
       ajint numoflines
    OUTPUT:
       xx1
       yy1
       xx2
       yy2

void
ajGraphDots (xx1, yy1, numofdots)
       PLFLT* xx1
       PLFLT* yy1
       ajint numofdots

void
ajGraphSymbols (numofdots, xx1, yy1, symbol)
       ajint numofdots
       PLFLT* xx1
       PLFLT* yy1
       ajint symbol

void
ajGraphTextLine (xx1, yy1, xx2, yy2, text, just)
       PLFLT xx1
       PLFLT yy1
       PLFLT xx2
       PLFLT yy2
       const char* text
       PLFLT just

void
ajGraphText (xx1, yy1, text, just)
       PLFLT xx1
       PLFLT yy1
       const char* text
       PLFLT just

void
ajGraphTextStart (xx1, yy1, text)
       PLFLT xx1
       PLFLT yy1
       const char* text

void
ajGraphTextEnd (xx1, yy1, text)
       PLFLT xx1
       PLFLT yy1
       const char* text

void
ajGraphTextMid (xx1, yy1, text)
       PLFLT xx1
       PLFLT yy1
       const char* text

void
ajGraphVertBars (numofpoints, x, ymin, ymax)
       ajint numofpoints
       PLFLT* x
       PLFLT* ymin
       PLFLT* ymax

void
ajGraphHoriBars (numofpoints, y, xmin, xmax)
       ajint numofpoints
       PLFLT* y
       PLFLT* xmin
       PLFLT* xmax

void
ajGraphInitSeq (thys, seq)
       AjPGraph thys
       const AjPSeq seq

void
ajGraphSetOut (thys, txt)
       AjPGraph thys
       const AjPStr txt

void
ajGraphSetOutC (thys, txt)
       AjPGraph thys
       const char* txt

void
ajGraphSetDir (thys, txt)
       AjPGraph thys
       const AjPStr txt

void
ajGraphPlpDataSetLineType (graphdata, type)
       AjPGraphPlpData graphdata
       ajint type

void
ajGraphxySetXStart (thys, val)
       AjPGraph thys
       float val

void
ajGraphxySetXEnd (thys, val)
       AjPGraph thys
       float val

void
ajGraphxySetYStart (thys, val)
       AjPGraph thys
       float val

void
ajGraphxySetYEnd (thys, val)
       AjPGraph thys
       float val

void
ajGraphPlpDataSetColour (graphdata, colour)
       AjPGraphPlpData graphdata
       ajint colour

void
ajGraphSetYTitle (thys, title)
       AjPGraph thys
       const AjPStr title

void
ajGraphSetYTitleC (thys, title)
       AjPGraph thys
       const char* title

void
ajGraphSetXTitle (thys, title)
       AjPGraph thys
       const AjPStr title

void
ajGraphSetXTitleC (thys, title)
       AjPGraph thys
       const char* title

void
ajGraphSetTitle (thys, title)
       AjPGraph thys
       const AjPStr title

void
ajGraphSetTitleC (thys, title)
       AjPGraph thys
       const char* title

void
ajGraphSetSubTitle (thys, title)
       AjPGraph thys
       const AjPStr title

void
ajGraphSetSubTitleC (thys, title)
       AjPGraph thys
       const char* title

void
ajGraphPlpDataSetYTitle (graphdata, title)
       AjPGraphPlpData graphdata
       const AjPStr title

void
ajGraphPlpDataSetYTitleC (graphdata, title)
       AjPGraphPlpData graphdata
       const char* title

void
ajGraphPlpDataSetXTitle (graphdata, title)
       AjPGraphPlpData graphdata
       const AjPStr title

void
ajGraphPlpDataSetXTitleC (graphdata, title)
       AjPGraphPlpData graphdata
       const char* title

void
ajGraphxyDel (pthis)
       AjPGraph& pthis
    OUTPUT:
       pthis

AjPGraphPlpData
ajGraphPlpDataNew ()
    OUTPUT:
       RETVAL

void
ajGraphPlpDataSetXY (graphdata, x, y)
       AjPGraphPlpData graphdata
       const float* x
       const float* y

void
ajGraphPlpDataCalcXY (graphdata, numofpoints, start, incr, y)
       AjPGraphPlpData graphdata
       ajint numofpoints
       float start
       float incr
       const float* y

void
ajGraphxySetXRangeII (thys, start, end)
       AjPGraph thys
       ajint start
       ajint end

void
ajGraphxySetYRangeII (thys, start, end)
       AjPGraph thys
       ajint start
       ajint end

AjPGraphPlpData
ajGraphPlpDataNewI (numofpoints)
       ajint numofpoints
    OUTPUT:
       RETVAL

ajint
ajGraphDataAdd (thys, graphdata)
       AjPGraph thys
       AjPGraphPlpData graphdata
    OUTPUT:
       RETVAL

ajint
ajGraphDataReplace (thys, graphdata)
       AjPGraph thys
       AjPGraphPlpData graphdata
    OUTPUT:
       RETVAL

AjPGraph
ajGraphNew ()
    OUTPUT:
       RETVAL

AjPGraph
ajGraphxyNewI (numsets)
       ajint numsets
    OUTPUT:
       RETVAL

void
ajGraphSetMulti (thys, numsets)
       AjPGraph thys
       ajint numsets
    OUTPUT:
       thys

void
ajGraphPlpDataSetTitle (graphdata, title)
       AjPGraphPlpData graphdata
       const AjPStr title

void
ajGraphPlpDataSetTitleC (graphdata, title)
       AjPGraphPlpData graphdata
       const char* title

void
ajGraphPlpDataSetSubTitle (graphdata, title)
       AjPGraphPlpData graphdata
       const AjPStr title

void
ajGraphPlpDataSetSubTitleC (graphdata, title)
       AjPGraphPlpData graphdata
       const char* title

void
ajGraphSetFlag (thys, flag, istrue)
       AjPGraph thys
       ajint flag
       AjBool istrue

void
ajGraphxySetOverLap (thys, overlap)
       AjPGraph thys
       AjBool overlap

void
ajGraphxySetGaps (thys, overlap)
       AjPGraph thys
       AjBool overlap

void
ajGraphxySetXBottom (thys, set)
       AjPGraph thys
       AjBool set

void
ajGraphxySetXTop (thys, set)
       AjPGraph thys
       AjBool set

void
ajGraphxySetYRight (thys, set)
       AjPGraph thys
       AjBool set

void
ajGraphxySetYLeft (thys, set)
       AjPGraph thys
       AjBool set

void
ajGraphxySetXTick (thys, set)
       AjPGraph thys
       AjBool set

void
ajGraphxySetYTick (thys, set)
       AjPGraph thys
       AjBool set

void
ajGraphxySetXLabel (thys, set)
       AjPGraph thys
       AjBool set

void
ajGraphxySetYLabel (thys, set)
       AjPGraph thys
       AjBool set

void
ajGraphSetTitleDo (thys, set)
       AjPGraph thys
       AjBool set

void
ajGraphSetSubTitleDo (thys, set)
       AjPGraph thys
       AjBool set

void
ajGraphxySetCirclePoints (thys, set)
       AjPGraph thys
       AjBool set

void
ajGraphxySetJoinPoints (thys, set)
       AjPGraph thys
       AjBool set

void
ajGraphxySetXLabelTop (thys, set)
       AjPGraph thys
       AjBool set

void
ajGraphxySetYLabelLeft (thys, set)
       AjPGraph thys
       AjBool set

void
ajGraphxySetXInvTicks (thys, set)
       AjPGraph thys
       AjBool set

void
ajGraphxySetYInvTicks (thys, set)
       AjPGraph thys
       AjBool set

void
ajGraphxySetXGrid (thys, set)
       AjPGraph thys
       AjBool set

void
ajGraphxySetYGrid (thys, set)
       AjPGraph thys
       AjBool set

void
ajGraphxySetMaxMin (thys, xmin, xmax, ymin, ymax)
       AjPGraph thys
       float xmin
       float xmax
       float ymin
       float ymax

void
ajGraphPlpDataSetMaxMin (graphdata, xmin, xmax, ymin, ymax)
       AjPGraphPlpData graphdata
       float xmin
       float xmax
       float ymin
       float ymax

void
ajGraphArrayMaxMin (array, npoints, min, max)
       const float* array
       ajint npoints
       float& min
       float& max
    OUTPUT:
       min
       max

void
ajGraphPlpDataSetMaxima (graphdata, xmin, xmax, ymin, ymax)
       AjPGraphPlpData graphdata
       float xmin
       float xmax
       float ymin
       float ymax

void
ajGraphPlpDataSetTypeC (graphdata, type)
       AjPGraphPlpData graphdata
       const char* type

void
ajGraphxyCheckMaxMin (thys)
       AjPGraph thys

void
ajGraphxyDisplay (thys, closeit)
       AjPGraph thys
       AjBool closeit

void
ajGraphAddRect (thys, xx1, yy1, xx2, yy2, colour, fill)
       AjPGraph thys
       float xx1
       float yy1
       float xx2
       float yy2
       ajint colour
       ajint fill

void
ajGraphAddText (thys, xx1, yy1, colour, text)
       AjPGraph thys
       float xx1
       float yy1
       ajint colour
       const char* text

void
ajGraphAddLine (thys, xx1, yy1, xx2, yy2, colour)
       AjPGraph thys
       float xx1
       float yy1
       float xx2
       float yy2
       ajint colour

void
ajGraphPlpDataDel (pthys)
       AjPGraphPlpData& pthys
    OUTPUT:
       pthys

void
ajGraphClear (thys)
       AjPGraph thys

void
ajGraphPlpDataAddRect (graphdata, xx1, yy1, xx2, yy2, colour, fill)
       AjPGraphPlpData graphdata
       float xx1
       float yy1
       float xx2
       float yy2
       ajint colour
       ajint fill

void
ajGraphPlpDataAddText (graphdata, xx1, yy1, colour, text)
       AjPGraphPlpData graphdata
       float xx1
       float yy1
       ajint colour
       const char* text

void
ajGraphPlpDataAddLine (graphdata, xx1, yy1, xx2, yy2, colour)
       AjPGraphPlpData graphdata
       float xx1
       float yy1
       float xx2
       float yy2
       ajint colour

void
ajGraphPrintType (outf, full)
       AjPFile outf
       AjBool full

PLFLT
ajGraphTextLength (xx1, yy1, xx2, yy2, text)
       PLFLT xx1
       PLFLT yy1
       PLFLT xx2
       PLFLT yy2
       const char* text
    OUTPUT:
       RETVAL

PLFLT
ajGraphTextHeight (xx1, xx2, yy1, yy2)
       PLFLT xx1
       PLFLT xx2
       PLFLT yy1
       PLFLT yy2
    OUTPUT:
       RETVAL

PLFLT
ajGraphDistPts (xx1, yy1, xx2, yy2)
       PLFLT xx1
       PLFLT yy1
       PLFLT xx2
       PLFLT yy2
    OUTPUT:
       RETVAL

float
ajGraphSetDefCharSize (size)
       float size
    OUTPUT:
       RETVAL

PLFLT
ajGraphFitTextOnLine (xx1, yy1, xx2, yy2, text, TextHeight)
       PLFLT xx1
       PLFLT yy1
       PLFLT xx2
       PLFLT yy2
       const char* text
       PLFLT TextHeight
    OUTPUT:
       RETVAL

void
ajGraphPartCircle (xcentre, ycentre, Radius, StartAngle, EndAngle)
       PLFLT xcentre
       PLFLT ycentre
       PLFLT Radius
       PLFLT StartAngle
       PLFLT EndAngle

PLFLT*
ajComputeCoord (xcentre, ycentre, Radius, Angle)
       PLFLT xcentre
       PLFLT ycentre
       PLFLT Radius
       PLFLT Angle
    OUTPUT:
       RETVAL

void
ajGraphDrawTextOnCurve (xcentre, ycentre, Radius, StartAngle, EndAngle, Text, just)
       PLFLT xcentre
       PLFLT ycentre
       PLFLT Radius
       PLFLT StartAngle
       PLFLT EndAngle
       const char* Text
       PLFLT just

void
ajGraphRectangleOnCurve (xcentre, ycentre, Radius, BoxHeight, StartAngle, EndAngle)
       PLFLT xcentre
       PLFLT ycentre
       PLFLT Radius
       PLFLT BoxHeight
       PLFLT StartAngle
       PLFLT EndAngle

ajint
ajGraphInfo (files)
       AjPList& files
    OUTPUT:
       RETVAL
       files

void
ajGraphFillRectangleOnCurve (xcentre, ycentre, Radius, BoxHeight, StartAngle, EndAngle)
       PLFLT xcentre
       PLFLT ycentre
       PLFLT Radius
       PLFLT BoxHeight
       PLFLT StartAngle
       PLFLT EndAngle

AjBool
ajGraphIsData (thys)
       const AjPGraph thys
    OUTPUT:
       RETVAL

void
ajGraphUnused ()

void
ajGraphSetDesc (thys, title)
       AjPGraph thys
       const AjPStr title

void
ajGraphSetTitlePlus (thys, title)
       AjPGraph thys
       const AjPStr title

ajint
ajGraphDataReplaceI (thys, graphdata, num)
       AjPGraph thys
       AjPGraphPlpData graphdata
       ajint num
    OUTPUT:
       RETVAL

float
ajGraphSetCharSize (size)
       float size
    OUTPUT:
       RETVAL

void
ajGraphAddTextScale (thys, xx1, yy1, colour, scale, text)
       AjPGraph thys
       float xx1
       float yy1
       ajint colour
       float scale
       const char* text

void
ajGraphPlpDataAddTextScale (graphdata, xx1, yy1, colour, scale, text)
       AjPGraphPlpData graphdata
       float xx1
       float yy1
       ajint colour
       float scale
       const char* text

void
ajGraphSetPage (width, height)
       ajuint width
       ajuint height

