/* -*- mode: text; coding: utf-8; tab-width: 4 -*- */

#include "Cv.inc"

MODULE = Cv::t		PACKAGE = Cv

# ============================================================
#  T_CvBox2D
# ============================================================

CvBox2D
cvBox2D(CvPoint2D32f center, CvSize2D32f size, float angle)
CODE:
	RETVAL.center = center;
	RETVAL.size = size;
	RETVAL.angle = angle;
OUTPUT:
	RETVAL

CvBox2D
CvBox2D(CvBox2D box)
CODE:
	RETVAL = box;
OUTPUT:
	RETVAL

# ============================================================
#  T_CvConnectedComp
# ============================================================

CvConnectedComp
cvConnectedComp(double area, CvScalar value, CvRect rect, CvSeq* contour)
CODE:
	RETVAL.area = area;
	RETVAL.value = value;
	RETVAL.rect = rect;
	RETVAL.contour = contour;
OUTPUT:
	RETVAL

CvConnectedComp
CvConnectedComp(CvConnectedComp cc)
CODE:
	RETVAL = cc;
OUTPUT:
	RETVAL


# ============================================================
#  T_CvPoint, T_CvPointPtr
# ============================================================

CvPoint
CvPoint(CvPoint pt)
CODE:
	RETVAL = pt;
OUTPUT:
	RETVAL

CvPoint*
cvPointPtr(int x, int y)
CODE:
	CvPoint pt = cvPoint(x, y);
	int length_RETVAL = 1;
	RETVAL = &pt;
OUTPUT:
	RETVAL


CvPoint*
CvPointPtr(CvPoint pt)
CODE:
	int length_RETVAL = 1;
	RETVAL = &pt;
OUTPUT:
	RETVAL


# ============================================================
#  T_CvPoint2D32f, T_CvPoint2D32fPtr
# ============================================================

CvPoint2D32f
CvPoint2D32f(CvPoint2D32f pt)
CODE:
	RETVAL = pt;
OUTPUT:
	RETVAL


CvPoint2D32f*
cvPoint2D32fPtr(float x, float y)
CODE:
	CvPoint2D32f pt = cvPoint2D32f(x, y);
	int length_RETVAL = 1;
	RETVAL = &pt;
OUTPUT:
	RETVAL


CvPoint2D32f*
CvPoint2D32fPtr(CvPoint2D32f pt)
CODE:
	int length_RETVAL = 1;
	RETVAL = &pt;
OUTPUT:
	RETVAL


# ============================================================
#  T_CvPoint2D64f, T_CvPoint2D64fPtr
# ============================================================

CvPoint2D64f
CvPoint2D64f(CvPoint2D64f pt)
CODE:
	RETVAL = pt;
OUTPUT:
	RETVAL

CvPoint2D64f*
cvPoint2D64fPtr(double x, double y)
CODE:
	CvPoint2D64f pt = cvPoint2D64f(x, y);
	int length_RETVAL = 1;
	RETVAL = &pt;
OUTPUT:
	RETVAL


CvPoint2D64f*
CvPoint2D64fPtr(CvPoint2D64f pt)
CODE:
	int length_RETVAL = 1;
	RETVAL = &pt;
OUTPUT:
	RETVAL


# ============================================================
#  T_CvPoint3D32f, T_CvPoint3D32fPtr
# ============================================================

CvPoint3D32f
CvPoint3D32f(CvPoint3D32f pt)
CODE:
	RETVAL = pt;
OUTPUT:
	RETVAL


CvPoint3D32f*
cvPoint3D32fPtr(float x, float y, float z)
CODE:
	CvPoint3D32f pt = cvPoint3D32f(x, y, z);
	int length_RETVAL = 1;
	RETVAL = &pt;
OUTPUT:
	RETVAL


CvPoint3D32f*
CvPoint3D32fPtr(CvPoint3D32f pt)
CODE:
	int length_RETVAL = 1;
	RETVAL = &pt;
OUTPUT:
	RETVAL


# ============================================================
#  T_CvPoint3D64f, T_CvPoint3D64fPtr
# ============================================================

CvPoint3D64f
CvPoint3D64f(CvPoint3D64f pt)
CODE:
	RETVAL = pt;
OUTPUT:
	RETVAL


CvPoint3D64f*
cvPoint3D64fPtr(double x, double y, double z)
CODE:
	CvPoint3D64f pt = cvPoint3D64f(x, y, z);
	int length_RETVAL = 1;
	RETVAL = &pt;
OUTPUT:
	RETVAL


CvPoint3D64f*
CvPoint3D64fPtr(CvPoint3D64f pt)
CODE:
	int length_RETVAL = 1;
	RETVAL = &pt;
OUTPUT:
	RETVAL


# ============================================================
#  T_CvRect
# ============================================================

CvRect
CvRect(CvRect rect)
CODE:
	RETVAL = rect;
OUTPUT:
	RETVAL


# ============================================================
#  T_CvScalar
# ============================================================

CvScalar
CvScalar(CvScalar scalar)
CODE:
	RETVAL = scalar;
OUTPUT:
	RETVAL

# ============================================================
#  T_CvSize
# ============================================================

CvSize
CvSize(CvSize size)
CODE:
	RETVAL = size;
OUTPUT:
	RETVAL

# ============================================================
#  T_CvSize2D32f
# ============================================================

CvSize2D32f
CvSize2D32f(CvSize2D32f size)
CODE:
	RETVAL = size;
OUTPUT:
	RETVAL

# ============================================================
#  T_CvTermCriteria
# ============================================================

CvTermCriteria
CvTermCriteria(CvTermCriteria term)
CODE:
	RETVAL = term;
OUTPUT:
	RETVAL


# ============================================================
#  T_floatPtr
# ============================================================

float*
floatPtr(float* values)
CODE:
	int length_RETVAL = length_values;
	RETVAL = values;
OUTPUT:
	RETVAL

double*
doublePtr(double* values)
CODE:
	int length_RETVAL = length_values;
	RETVAL = values;
OUTPUT:
	RETVAL


# ============================================================
#  T_intPtr
# ============================================================

int*
intPtr(int* values)
CODE:
	int length_RETVAL = length_values;
	RETVAL = values;
OUTPUT:
	RETVAL
