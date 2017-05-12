#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_graphxml		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajgraphxml.c: automatically generated

AjPXmlNode
ajXmlNodeNew ()
    OUTPUT:
       RETVAL

AjPGraphXml
ajXmlFileNew ()
    OUTPUT:
       RETVAL

void
ajXmlNodeDel (thys)
       AjPXmlNode& thys
    OUTPUT:
       thys

void
ajXmlFileDel (thys)
       AjPGraphXml& thys
    OUTPUT:
       thys

AjBool
ajXmlSetMaxMin (file, xMin, yMin, xMax, yMax)
       AjPGraphXml file
       double xMin
       double yMin
       double xMax
       double yMax
    OUTPUT:
       RETVAL
       file

AjBool
ajXmlWriteFile (file, filename)
       AjPGraphXml file
       const AjPStr filename
    OUTPUT:
       RETVAL
       file

AjBool
ajXmlWriteStdout (file)
       AjPGraphXml file
    OUTPUT:
       RETVAL
       file

AjBool
ajXmlSetSource (file, title)
       AjPGraphXml file
       const AjPStr title
    OUTPUT:
       RETVAL
       file

AjBool
ajXmlAddMainTitleC (file, title)
       AjPGraphXml file
       const char * title
    OUTPUT:
       RETVAL
       file

AjBool
ajXmlAddXTitleC (file, title)
       AjPGraphXml file
       const char * title
    OUTPUT:
       RETVAL
       file

AjBool
ajXmlAddYTitleC (file, title)
       AjPGraphXml file
       const char * title
    OUTPUT:
       RETVAL
       file

AjBool
ajXmlAddMainTitle (file, title)
       AjPGraphXml file
       const AjPStr title
    OUTPUT:
       RETVAL
       file

AjBool
ajXmlAddXTitle (file, title)
       AjPGraphXml file
       const AjPStr title
    OUTPUT:
       RETVAL
       file

AjBool
ajXmlAddYTitle (file, title)
       AjPGraphXml file
       const AjPStr title
    OUTPUT:
       RETVAL
       file

void
ajXmlAddTextCentred (file, x, y, size, angle, fontFamily, fontStyle, text)
       AjPGraphXml file
       double x
       double y
       double size
       double angle
       const AjPStr fontFamily
       const AjPStr fontStyle
       const AjPStr text
    OUTPUT:
       file

void
ajXmlAddTextC (file, x, y, size, angle, fontFamily, fontStyle, text)
       AjPGraphXml file
       double x
       double y
       double size
       double angle
       const char * fontFamily
       const char * fontStyle
       const char * text
    OUTPUT:
       file

void
ajXmlAddText (file, x, y, size, angle, fontFamily, fontStyle, text)
       AjPGraphXml file
       double x
       double y
       double size
       double angle
       const AjPStr fontFamily
       const AjPStr fontStyle
       const AjPStr text
    OUTPUT:
       file

void
ajXmlAddTextWithCJustify (file, x, y, size, angle, fontFamily, fontStyle, text, horizontal, leftToRight, topToBottom, justifyMajor, justifyMinor)
       AjPGraphXml file
       double x
       double y
       double size
       double angle
       const AjPStr fontFamily
       const AjPStr fontStyle
       const AjPStr text
       AjBool horizontal
       AjBool leftToRight
       AjBool topToBottom
       const char * justifyMajor
       const char * justifyMinor
    OUTPUT:
       file

void
ajXmlAddTextWithJustify (file, x, y, size, angle, fontFamily, fontStyle, text, horizontal, leftToRight, topToBottom, justifyMajor, justifyMinor)
       AjPGraphXml file
       double x
       double y
       double size
       double angle
       const AjPStr fontFamily
       const AjPStr fontStyle
       const AjPStr text
       AjBool horizontal
       AjBool leftToRight
       AjBool topToBottom
       const AjPStr justifyMajor
       const AjPStr justifyMinor
    OUTPUT:
       file

void
ajXmlAddTextOnArc (file, xCentre, yCentre, startAngle, endAngle, radius, size, fontFamily, fontStyle, text)
       AjPGraphXml file
       double xCentre
       double yCentre
       double startAngle
       double endAngle
       double radius
       double size
       const AjPStr fontFamily
       const AjPStr fontStyle
       const AjPStr text
    OUTPUT:
       file

void
ajXmlAddJoinedLineSetEqualGapsF (file, y, numberOfPoints, startX, increment)
       AjPGraphXml file
       const float* y
       int numberOfPoints
       float startX
       float increment
    OUTPUT:
       file

void
ajXmlAddJoinedLineSetF (file, x, y, numberOfPoints)
       AjPGraphXml file
       const float* x
       const float* y
       int numberOfPoints
    OUTPUT:
       file

void
ajXmlAddJoinedLineSet (file, x, y, numberOfPoints)
       AjPGraphXml file
       const double* x
       const double* y
       int numberOfPoints
    OUTPUT:
       file

void
ajXmlAddLine (file, x1, y1, x2, y2)
       AjPGraphXml file
       double x1
       double y1
       double x2
       double y2
    OUTPUT:
       file

void
ajXmlAddLineF (file, x1, y1, x2, y2)
       AjPGraphXml file
       float x1
       float y1
       float x2
       float y2
    OUTPUT:
       file

void
ajXmlAddPoint (file, x1, y1)
       AjPGraphXml file
       double x1
       double y1
    OUTPUT:
       file

void
ajXmlAddHistogramEqualGapsF (file, y, numPoints, startX, xGap)
       AjPGraphXml file
       const float* y
       int numPoints
       float startX
       float xGap
    OUTPUT:
       file

void
ajXmlAddRectangleSet (file, x1, y1, x2, y2, numPoints, fill)
       AjPGraphXml file
       const double* x1
       const double* y1
       const double* x2
       const double* y2
       int numPoints
       AjBool fill
    OUTPUT:
       file

void
ajXmlAddRectangle (file, x1, y1, x2, y2, fill)
       AjPGraphXml file
       double x1
       double y1
       double x2
       double y2
       AjBool fill
    OUTPUT:
       file

void
ajXmlAddCylinder (file, x1, y1, x2, y2, width)
       AjPGraphXml file
       double x1
       double y1
       double x2
       double y2
       double width
    OUTPUT:
       file

AjBool
ajXmlAddPointLabelCircle (file, angle, xCentre, yCentre, radius, length, size, fontFamily, fontStyle, text)
       AjPGraphXml file
       double angle
       double xCentre
       double yCentre
       double radius
       double length
       double size
       const AjPStr fontFamily
       const AjPStr fontStyle
       const AjPStr text
    OUTPUT:
       RETVAL
       file

AjBool
ajXmlAddSectionLabelCircle (file, startAngle, endAngle, xCentre, yCentre, radius, width, labelArmAngle, labelStyle, textPosition, size, fontFamily, fontStyle, text)
       AjPGraphXml file
       double startAngle
       double endAngle
       double xCentre
       double yCentre
       double radius
       double width
       double labelArmAngle
       const AjPStr labelStyle
       double textPosition
       double size
       const AjPStr fontFamily
       const AjPStr fontStyle
       const AjPStr text
    OUTPUT:
       RETVAL
       file

AjBool
ajXmlAddPointLabelLinear (file, angle, xPoint, yPoint, length, textParallelToLine, size, fontFamily, fontStyle, text)
       AjPGraphXml file
       double angle
       double xPoint
       double yPoint
       double length
       AjBool textParallelToLine
       double size
       const AjPStr fontFamily
       const AjPStr fontStyle
       const AjPStr text
    OUTPUT:
       RETVAL
       file

AjBool
ajXmlAddSectionLabelLinear (file, xStart, yStart, xEnd, yEnd, width, labelArmLength, labelStyle, textPosition, size, fontFamily, fontStyle, text)
       AjPGraphXml file
       double xStart
       double yStart
       double xEnd
       double yEnd
       double width
       double labelArmLength
       const AjPStr labelStyle
       double textPosition
       double size
       const AjPStr fontFamily
       const AjPStr fontStyle
       const AjPStr text
    OUTPUT:
       RETVAL
       file

AjBool
ajXmlAddSquareResidueLinear (file, residue, x, y)
       AjPGraphXml file
       char residue
       float x
       float y
    OUTPUT:
       RETVAL
       file

AjBool
ajXmlAddOctagonalResidueLinear (file, residue, x, y)
       AjPGraphXml file
       char residue
       float x
       float y
    OUTPUT:
       RETVAL
       file

AjBool
ajXmlAddDiamondResidueLinear (file, residue, x, y)
       AjPGraphXml file
       char residue
       float x
       float y
    OUTPUT:
       RETVAL
       file

AjBool
ajXmlAddNakedResidueLinear (file, residue, x, y)
       AjPGraphXml file
       char residue
       float x
       float y
    OUTPUT:
       RETVAL
       file

AjBool
ajXmlAddSquareResidue (file, residue, radius, angle)
       AjPGraphXml file
       char residue
       double radius
       double angle
    OUTPUT:
       RETVAL
       file

AjBool
ajXmlAddOctagonalResidue (file, residue, radius, angle)
       AjPGraphXml file
       char residue
       double radius
       double angle
    OUTPUT:
       RETVAL
       file

AjBool
ajXmlAddDiamondResidue (file, residue, radius, angle)
       AjPGraphXml file
       char residue
       double radius
       double angle
    OUTPUT:
       RETVAL
       file

AjBool
ajXmlAddNakedResidue (file, residue, radius, angle)
       AjPGraphXml file
       char residue
       double radius
       double angle
    OUTPUT:
       RETVAL
       file

float
ajXmlFitTextOnLine (x1, y1, x2, y2, text)
       float x1
       float y1
       float x2
       float y2
       const AjPStr text
    OUTPUT:
       RETVAL

void
ajXmlGetColour (file, r, g, b)
       const AjPGraphXml file
       double& r
       double& g
       double& b
    OUTPUT:
       r
       g
       b

void
ajXmlSetColour (file, r, g, b)
       AjPGraphXml file
       double r
       double g
       double b
    OUTPUT:
       file

void
ajXmlSetColourFromCode (file, colour)
       AjPGraphXml file
       ajint colour
    OUTPUT:
       file

AjPGraphXml
ajXmlCreateNewOutputFile ()
    OUTPUT:
       RETVAL

void
ajXmlAddGraphic (file, type)
       AjPGraphXml file
       const AjPStr type
    OUTPUT:
       file

void
ajXmlAddGraphicC (file, type)
       AjPGraphXml file
       const char * type
    OUTPUT:
       file

void
ajXmlAddArc (file, xCentre, yCentre, startAngle, endAngle, radius)
       AjPGraphXml file
       double xCentre
       double yCentre
       double startAngle
       double endAngle
       double radius
    OUTPUT:
       file

void
ajXmlAddCircleF (file, xCentre, yCentre, radius)
       AjPGraphXml file
       float xCentre
       float yCentre
       float radius
    OUTPUT:
       file

void
ajXmlAddCircle (file, xCentre, yCentre, radius)
       AjPGraphXml file
       double xCentre
       double yCentre
       double radius
    OUTPUT:
       file

void
ajXmlAddGroutOption (file, name, value)
       AjPGraphXml file
       const AjPStr name
       const AjPStr value
    OUTPUT:
       file

void
ajXmlAddGroutOptionC (file, name, value)
       AjPGraphXml file
       const char * name
       const char * value
    OUTPUT:
       file

