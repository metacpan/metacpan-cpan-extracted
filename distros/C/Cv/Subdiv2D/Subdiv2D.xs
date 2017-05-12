/* -*- mode: text; coding: utf-8; tab-width: 4 -*- */

#include "Cv.inc"

MODULE = Cv::Subdiv2D		PACKAGE = Cv::Subdiv2D

# ============================================================
#  imgproc. Image Processing: Planar Subdivisions
# ============================================================

CvSeq*
edges(CvSubdiv2D* subdiv)
CODE:
	RETVAL = (CvSeq*)subdiv->edges;
OUTPUT:
	RETVAL		

void
cvCalcSubdivVoronoi2D(CvSubdiv2D* subdiv)
# ALIAS:	Cv::cvCalcSubdivVoronoi2D = 1

void
cvClearSubdivVoronoi2D(CvSubdiv2D* subdiv)
# ALIAS:	Cv::cvClearSubdivVoronoi2D = 1

CvSubdiv2D*
cvCreateSubdivDelaunay2D(CvRect rect, CvMemStorage* storage)
# ALIAS:	Cv::cvCreateSubdivDelaunay2D = 1

CvSubdiv2DPoint
cvFindNearestPoint2D(CvSubdiv2D* subdiv, CvPoint2D32f pt)
CODE:
	CvSubdiv2DPoint* p = cvFindNearestPoint2D(subdiv, pt);
	if (p) RETVAL = *p; else XSRETURN_UNDEF;
OUTPUT:
	RETVAL

CvSubdiv2DPoint
cvSubdiv2DEdgeOrg(CvSubdiv2DEdge edge)
# ALIAS:	Cv::cvSubdiv2DEdgeOrg = 1
CODE:
	CvSubdiv2DPoint* p = cvSubdiv2DEdgeOrg(edge);
	if (p) RETVAL = *p; else XSRETURN_UNDEF;
OUTPUT:
	RETVAL

CvSubdiv2DPoint
cvSubdiv2DEdgeDst(CvSubdiv2DEdge edge)
# ALIAS:	Cv::cvSubdiv2DEdgeDst = 1
CODE:
	CvSubdiv2DPoint* p = cvSubdiv2DEdgeDst(edge);
	if (p) RETVAL = *p; else XSRETURN_UNDEF;
OUTPUT:
	RETVAL

CvSubdiv2DEdge
cvSubdiv2DGetEdge(CvSubdiv2DEdge edge, CvNextEdgeType type)
# ALIAS:	Cv::cvSubdiv2DGetEdge = 1

CvSubdiv2DEdge
cvSubdiv2DNextEdge(CvSubdiv2DEdge edge)
# ALIAS:	Cv::cvSubdiv2DNextEdge = 1

CvSubdiv2DPointLocation
cvSubdiv2DLocate(CvSubdiv2D* subdiv, CvPoint2D32f pt, OUT CvSubdiv2DEdge edge, vertex = NO_INIT)
INPUT:
	CvSubdiv2DPoint* &vertex = NO_INIT
CODE:
	RETVAL = cvSubdiv2DLocate(subdiv, pt, &edge, NULL);
OUTPUT:
	edge

CvSubdiv2DEdge
cvSubdiv2DRotateEdge(CvSubdiv2DEdge edge, int rotate)
# ALIAS:	Cv::cvSubdiv2DRotateEdge = 1

CvSubdiv2DPoint
cvSubdivDelaunay2DInsert(CvSubdiv2D* subdiv, CvPoint2D32f pt)
CODE:
	CvSubdiv2DPoint* p = cvSubdivDelaunay2DInsert(subdiv, pt);
	if (p) RETVAL = *p; else XSRETURN_UNDEF;
OUTPUT:
	RETVAL
