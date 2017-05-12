/* -*- mode: text; coding: utf-8; tab-width: 4 -*- */

#include "Cv.inc"

#define bless(st0, class, retval) \
    sv_setref_pv(st0 = sv_newmortal(), class, (void*)retval);

static void delete_callback(AV* av)
{
	SV* sv;
	while ((sv = av_shift(av)) && sv != &PL_sv_undef) {
		callback_t* callback = INT2PTR(callback_t*, SvIV(sv));
		if (callback) {
			if (callback->callback) SvREFCNT_dec(callback->callback);
			if (callback->u.t.value) SvREFCNT_dec(callback->u.t.value);
			safefree(callback);
		} else {
			Perl_croak(aTHX_ "callback is 0");
		}
	}
}

static void delete_all_callback(const char* hash)
{
	HV* hv = get_hv(hash, 0);
	if (hv) { HE* he;
		hv_iterinit(hv);
		while (he = hv_iternext(hv)) {
			SV* sv = hv_iterval(hv, he);
			delete_callback((AV*)SvRV(sv));
		}
		hv_undef(hv);
	}
}

static void delete_win_callback(const char* key, const char* hash)
{
	HV* hv = get_hv(hash, 0);
	if (hv) {
		SV* sv = hv_delete(hv, key, strlen(key), 0);
		if (sv && SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV) {
			delete_callback((AV*)SvRV(sv));
		}
	}
}

static void cb_trackbar(int pos)
{
	HV* Cv_TRACKBAR = get_hv("Cv::TRACKBAR", 0);
	if (Cv_TRACKBAR) { HE* he;
		hv_iterinit(Cv_TRACKBAR);
		while (he = hv_iternext(Cv_TRACKBAR)) {
			SV* sv = hv_iterval(Cv_TRACKBAR, he);
			AV* av = (AV*)SvRV(sv);
			int i, n = av_len(av);
			for (i = 0; i <= n; i++) {
				SV* sv = *av_fetch(av, i, 0);
				callback_t* p = INT2PTR(callback_t*, SvIV(sv));
				if (p && p->u.t.pos != p->u.t.lastpos) {
					p->u.t.lastpos = p->u.t.pos;
					if (p->u.t.value) sv_setiv(p->u.t.value, p->u.t.pos);
					if (p->callback) {
						dSP;
						ENTER;
						SAVETMPS;
						PUSHMARK(SP);
						XPUSHs(sv_2mortal(newSViv(p->u.t.pos)));
						PUTBACK;
						// call_sv(p->callback, G_EVAL|G_DISCARD);
						call_sv(p->callback, G_DISCARD);
						FREETMPS;
						LEAVE;
					}
				}
			}
		}
	}
}


static void cb_mouse(int event, int x, int y, int flags, VOID* userdata)
{
	callback_t *p = (callback_t*)userdata;
	if (p && p->callback) {
		dSP;
		ENTER;
		SAVETMPS;
		PUSHMARK(SP);
		EXTEND(SP, 5);
		PUSHs(sv_2mortal(newSViv(event)));
		PUSHs(sv_2mortal(newSViv(x)));
		PUSHs(sv_2mortal(newSViv(y)));
		PUSHs(sv_2mortal(newSViv(flags)));
		PUSHs(p->u.m.userdata? p->u.m.userdata : &PL_sv_undef);
		PUTBACK;
		// call_sv(p->callback, G_EVAL|G_DISCARD);
		call_sv(p->callback, G_DISCARD);
		FREETMPS;
		LEAVE;
	}
}

static int cb_error(int status, const char* func_name, const char* err_msg,
					const char* file_name, int line, VOID* userdata)  {
	SV* handler = get_sv("Cv::ERROR", 0);
	cvSetErrStatus(0);
	if (handler && SvROK(handler) && SvTYPE(SvRV(handler)) == SVt_PVCV) {
		dSP;
		ENTER;
		SAVETMPS;
		PUSHMARK(SP);
		EXTEND(SP, 5);
		PUSHs(sv_2mortal(newSViv(status)));
		PUSHs(sv_2mortal(newSVpv(func_name, 0)));
		PUSHs(sv_2mortal(newSVpv(err_msg, 0)));
		PUSHs(sv_2mortal(newSVpv(file_name, 0)));
		PUSHs(sv_2mortal(newSViv(line)));
		PUTBACK;
		call_sv(handler, G_VOID|G_DISCARD);
		FREETMPS;
		LEAVE;
		return 0;
	} else {
		Perl_croak(aTHX_ "cb_error: can't call Cv::ERROR");
		return -1;
	}
}


SV*
newSVpvn_ro(const char* s, const STRLEN len)
{
#if 1
	SV* sv = newSV(0);
	sv_upgrade(sv, SVt_PV);
	SvPV_set(sv, (char*)s);
	SvCUR_set(sv, len);
	SvPOK_on(sv);
	SvREADONLY_on(sv);
    return sv;
#else  /* test for compatibility */
    return newSVpvn(s, len);
#endif
}


static SV *unbless(SV * rv)
{
    SV* sv = SvRV(rv);
    if (SvREADONLY(sv)) Perl_croak(aTHX_ "%s", PL_no_modify);
    SvREFCNT_dec(SvSTASH(sv));
    SvSTASH(sv) = NULL;
    SvOBJECT_off(sv);
    if (SvTYPE(sv) != SVt_PVIO) PL_sv_objcount--;
    SvAMAGIC_off(rv);
#ifdef SvUNMAGIC
    SvUNMAGIC(sv);
#endif
    return rv;
}


#if _CV_VERSION() >= _VERSION(2,4,0)
#ifdef __cplusplus
#define HAVE_cvExtractMSER 1
void
cvExtractMSER(CvArr* img, CvArr* mask, CvSeq** contours, CvMemStorage* storage, CvMSERParams params)
{
	MSER mser = MSER(params.delta, params.minArea, params.maxArea, params.maxVariation, params.minDiversity, params.maxEvolution, params.areaThreshold, params.minMargin, params.edgeBlurSize);
	cv::Mat _img = cv::cvarrToMat(img);
	vector<vector<Point> > _contours;
	if (mask) {
		cv::Mat _mask = cv::cvarrToMat(mask);
		mser(_img, _contours, _mask);
	} else {
		mser(_img, _contours);
	}
	*contours = cvCreateSeq(0, sizeof(CvSeq), sizeof(CvSeq*), storage);
	for (int i = (int)_contours.size() - 1; i >= 0; i--) {
		const vector<Point>& r = _contours[i];
		CvSeq* _contour = cvCreateSeq(CV_SEQ_KIND_GENERIC|CV_32SC2,
			   sizeof(CvContour), sizeof(CvPoint), storage);
		CvContour* contour = (CvContour*)_contour;
		for (int j = 0; j < (int)r.size(); j++) {
			CvPoint pt = r[j];
			cvSeqPush(_contour, (void*)&pt);
		}
		// cvBoundingRect(contour);
		contour->color = 0;
		cvSeqPush(*contours, &contour);
	}
}
#endif /* !__cplusplus */
#elif _CV_VERSION() >= _VERSION(2,0,0)
#define HAVE_cvExtractMSER 1
#endif

const char*
cvGetBuildInformation()
{
#if defined __cplusplus && _CV_VERSION() >= _VERSION(2,4,0)
	string s = cv::getBuildInformation();
	return s.c_str();
#else
	return "";
#endif
}

MODULE = Cv	PACKAGE = Cv

# ============================================================
#  core. The Core Functionality: Basic Structures
# ============================================================

MODULE = Cv	PACKAGE = Cv::Arr
# ====================
IV
phys(CvArr* arr)
CODE:
	RETVAL = PTR2IV(arr);
OUTPUT:
	RETVAL

MODULE = Cv	PACKAGE = Cv::Mat
# ====================

int
refcount(const CvMat* mat)
CODE:
	RETVAL = mat->refcount? *mat->refcount : -1;
OUTPUT:
	RETVAL


MODULE = Cv	PACKAGE = Cv::MatND
# ====================

int
refcount(const CvMatND* mat)
CODE:
	RETVAL = mat->refcount? *mat->refcount : -1;
OUTPUT:
	RETVAL


MODULE = Cv	PACKAGE = Cv::SparseMat
# ====================

int
refcount(const CvSparseMat* mat)
CODE:
	RETVAL = mat->refcount? *mat->refcount : -1;
OUTPUT:
	RETVAL


MODULE = Cv	PACKAGE = Cv::Image
# ====================

int
depth(IplImage* image)
CODE:
	RETVAL = image->depth;
OUTPUT:
	RETVAL

int
origin(IplImage* image, int value = NO_INIT)
CODE:
	RETVAL = image->origin;
	if (items == 2) image->origin = value;
OUTPUT:
	RETVAL


MODULE = Cv	PACKAGE = Cv::Arr
# ====================
int
nChannels(CvArr* arr)
ALIAS: channels = 1
CODE:
	int type = cvGetElemType(arr);
	RETVAL = CV_MAT_CN(type);
OUTPUT:
	RETVAL

int
depth(CvArr* arr)
PREINIT:
	static int cv2ipl_depth[] = {
		IPL_DEPTH_8U,
		IPL_DEPTH_8S,
		IPL_DEPTH_16U,
		IPL_DEPTH_16S,
		IPL_DEPTH_32S,
		IPL_DEPTH_32F,
		IPL_DEPTH_64F,
		0,
	};
INIT:
	RETVAL = 0;
CODE:
	int type = cvGetElemType(arr);
	int cvdepth = CV_MAT_DEPTH(type);
	if (cvdepth >= 0 && cvdepth < DIM(cv2ipl_depth))
		RETVAL = cv2ipl_depth[cvdepth];
	if (RETVAL == 0) XSRETURN_UNDEF;
OUTPUT:
	RETVAL

int
dims(CvArr* arr)
CODE:
	RETVAL = cvGetDims(arr, NULL);
OUTPUT:
	RETVAL

int
rows(CvArr* arr)
ALIAS: height = 1
CODE:
	int sizes[CV_MAX_DIM];
	int dims = cvGetDims(arr, sizes);
	if (dims >= 1) {
		RETVAL = sizes[0];
	} else {
		RETVAL = 0;
	}
OUTPUT:
	RETVAL

int
cols(CvArr* arr)
ALIAS: width = 1
CODE:
	int sizes[CV_MAX_DIM];
	int dims = cvGetDims(arr, sizes);
	if (dims >= 2) {
		RETVAL = sizes[1];
	} else {
		RETVAL = 0;
	}
OUTPUT:
	RETVAL

AV*
sizes(CvArr* arr)
CODE:
	int sizes[CV_MAX_DIM];
	int dims = cvGetDims(arr, sizes); int i;
	RETVAL = newAV();
	for (i = 0; i < dims; i++) {
		av_push(RETVAL, newSViv(sizes[i]));
	}
OUTPUT:
	RETVAL

STRLEN
total(CvArr* arr)
CODE:
	int sizes[CV_MAX_DIM];
	int dims = cvGetDims(arr, sizes); int i;
	RETVAL = sizes[0];
	for (i = 1; i < dims; i++)
		RETVAL *= sizes[i];
OUTPUT:
	RETVAL


# ============================================================
#  core. The Core Functionality: Operations on Arrays
# ============================================================

MODULE = Cv	PACKAGE = Cv::Arr
# ====================
void
cvAbsDiff(const CvArr* src1, const CvArr* src2, CvArr* dst)
POSTCALL:
	ST(0) = ST(2);
	XSRETURN(1);

void
cvAbsDiffS(const CvArr* src, CvScalar value, CvArr* dst)
C_ARGS: src, dst, value
POSTCALL:
	ST(0) = ST(2);
	XSRETURN(1);

void
cvAdd(const CvArr* src1, const CvArr* src2, CvArr* dst, const CvArr* mask=NULL)
POSTCALL:
	ST(0) = ST(2);
	XSRETURN(1);

void
cvAddS(const CvArr* src, CvScalar value, CvArr* dst, const CvArr* mask=NULL)
POSTCALL:
	ST(0) = ST(2);
	XSRETURN(1);

void
cvAddWeighted(const CvArr* src1, double alpha, const CvArr* src2, double beta, double gamma, CvArr* dst)
POSTCALL:
	ST(0) = ST(5);
	XSRETURN(1);

void
cvAnd(const CvArr* src1, const CvArr* src2, CvArr* dst, const CvArr* mask=NULL)
POSTCALL:
	ST(0) = ST(2);
	XSRETURN(1);

void
cvAndS(const CvArr* src, CvScalar value, CvArr* dst, const CvArr* mask=NULL)
POSTCALL:
	ST(0) = ST(2);
	XSRETURN(1);

CvScalar
cvAvg(const CvArr* arr, const CvArr* mask=NULL)

void
cvAvgSdv(const CvArr* arr, OUT CvScalar mean, OUT CvScalar stdDev, const CvArr* mask = NULL)

MODULE = Cv	PACKAGE = Cv
void
cvCalcCovarMatrix(const CvArr** vects, CvArr* covMat, CvArr* avg, int flags)
C_ARGS: vects, length(vects), covMat, avg, flags
POSTCALL:
	ST(0) = ST(2);
	XSRETURN(1);

MODULE = Cv	PACKAGE = Cv::Arr
void
cvCartToPolar(const CvArr* x, const CvArr* y, CvArr* magnitude, CvArr* angle=NULL, int angleInDegrees=0)
ALIAS: Cv::cvCartToPolar = 1

MODULE = Cv	PACKAGE = Cv
float
cvCbrt(float value)

int
cvCeil(double value)

MODULE = Cv	PACKAGE = Cv::Arr
void
cvClearND(CvArr* arr, int* idx)
ALIAS: cvClear = 1

MODULE = Cv	PACKAGE = Cv::Image
IplImage*
cvCloneImage(const IplImage* image)
ALIAS: cvClone = 1

MODULE = Cv	PACKAGE = Cv::Mat
CvMat*
cvCloneMat(const CvMat* mat)
ALIAS: cvClone = 1

MODULE = Cv	PACKAGE = Cv::MatND
CvMatND*
cvCloneMatND(const CvMatND* mat)
ALIAS: cvClone = 1

MODULE = Cv	PACKAGE = Cv::SparseMat
CvSparseMat*
cvCloneSparseMat(const CvSparseMat* mat)
ALIAS: cvClone = 1

MODULE = Cv	PACKAGE = Cv::Arr
void
cvCmp(const CvArr* src1, const CvArr* src2, CvArr* dst, int cmpOp)
POSTCALL:
	ST(0) = ST(2);
	XSRETURN(1);

void
cvCmpS(const CvArr* src, double value, CvArr* dst, int cmpOp)
POSTCALL:
	ST(0) = ST(2);
	XSRETURN(1);

void
cvConvertScale(const CvArr* src, CvArr* dst, double scale=1, double shift=0)
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

void
cvConvertScaleAbs(const CvArr* src, CvArr* dst, double scale=1, double shift=0)
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

MODULE = Cv	PACKAGE = Cv
IplImage*
cvCreateImage(CvSize size, int depth, int channels)

IplImage*
cvCreateImageHeader(CvSize size, int depth, int channels)

CvMat*
cvCreateMat(int rows, int cols, int type)

CvMat*
cvCreateMatHeader(int rows, int cols, int type)

CvMatND*
cvCreateMatND(int* sizes, int type)
C_ARGS: length(sizes), sizes, type

CvMatND*
cvCreateMatNDHeader(const int* sizes, int type)
C_ARGS: length(sizes), sizes, type

CvSparseMat*
cvCreateSparseMat(int* sizes, int type)
C_ARGS: length(sizes), sizes, type


MODULE = Cv	PACKAGE = Cv::Arr
void
cvCopy(const CvArr* src, CvArr* dst, const CvArr* mask=NULL)
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

int
cvCountNonZero(const CvArr* arr)

void
cvCreateData(CvArr* arr)

void
cvCrossProduct(const CvArr* src1, const CvArr* src2, CvArr* dst)
POSTCALL:
	ST(0) = ST(2);
	XSRETURN(1);

void
cvDCT(const CvArr* src, CvArr* dst, int flags)
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

void
cvDFT(const CvArr* src, CvArr* dst, int flags, int nonzeroRows=0)
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

void
cvDecRefData(CvArr* arr)
POSTCALL:
	XSRETURN(1);

double
cvDet(const CvArr* mat)

void
cvDiv(const CvArr* src1, const CvArr* src2, CvArr* dst, double scale=1)
POSTCALL:
	ST(0) = ST(2);
	XSRETURN(1);

double
cvDotProduct(const CvArr* src1, const CvArr* src2)

void
cvEigenVV(CvArr* mat, CvArr* evects, CvArr* evals, double eps=0, int lowindex = -1, int highindex = -1)
CODE:
	cvEigenVV(mat, evects, evals, eps
#if _CV_VERSION() >= _VERSION(2,0,0)
		, lowindex, highindex
#endif
		);

void
cvExp(const CvArr* src, CvArr* dst)
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

MODULE = Cv	PACKAGE = Cv
float
cvFastArctan(float y, float x)

MODULE = Cv	PACKAGE = Cv::Arr
void
cvFlip(const CvArr* src, CvArr* dst=NULL, int flipMode=0)
POSTCALL:
	if (dst) ST(0) = ST(1);
	XSRETURN(1);

MODULE = Cv	PACKAGE = Cv
int
cvFloor(double value)

MODULE = Cv	PACKAGE = Cv::Arr
void
cvGEMM(const CvArr* src1, const CvArr* src2, double alpha, const CvArr* src3, double beta, CvArr* dst, int tABC=0)
POSTCALL:
	ST(0) = ST(5);
	XSRETURN(1);

#PERL# CvScalar cvGet1D(const CvArr* arr, int idx0)
#PERL# CvScalar cvGet2D(const CvArr* arr, int idx0, int idx1)
#PERL# CvScalar cvGet3D(const CvArr* arr, int idx0, int idx1, int idx2)

CvScalar
cvGetND(const CvArr* arr, int* idx)

CvMat*
cvGetCols(const CvArr* arr, CvMat* submat, int startCol, int endCol = NO_INIT)
INIT:
	if (items < 4) endCol = startCol + 1;
OUTPUT: RETVAL ST(0) = SvREFCNT_inc(ST(1));

CvMat*
cvGetDiag(const CvArr* arr, CvMat* submat, int diag=0)
OUTPUT: submat
OUTPUT: RETVAL ST(0) = SvREFCNT_inc(ST(1));

#C# int cvGetDims(const CvArr* arr, int* sizes=NULL)
void
cvGetDims(const CvArr* arr, ...)
ALIAS: GetDims = 1
ALIAS: getDims = 2
PROTOTYPE: $;\@
PPCODE:
	const int verbose = 0;
	int sizes[CV_MAX_DIM]; int i;
	int dims = cvGetDims(arr, sizes);
	if (items == 2) {
		AV* av_sizes = (AV*)SvRV(ST(1)); av_clear(av_sizes);
		for (i = 0; i < dims; i++) {
			av_push(av_sizes, newSViv(sizes[i]));
		}
	}
	I32 gimme = GIMME_V; /* wantarray */
	if (gimme == G_VOID) {
		if (verbose) fprintf(stderr, "Context is Void\n");
	} else if (gimme == G_SCALAR) {
		if (verbose) fprintf(stderr, "Context is Scalar\n");
		XPUSHs(sv_2mortal(newSViv(dims)));
	} else if (gimme == G_ARRAY) {
		if (verbose) fprintf(stderr, "Context is Array\n");
		EXTEND(SP, dims);
		for (i = 0; i < dims; i++) {
			PUSHs(sv_2mortal(newSViv(sizes[i])));
		}
	}

int
cvGetDimSize(const CvArr* arr, int index)

int
cvGetElemType(const CvArr* arr)
ALIAS: cvType = 1

IplImage*
cvGetImage(const CvArr* arr, IplImage* imageHeader)

int
cvGetImageCOI(const IplImage* image)
ALIAS: cvGetCOI = 1

CvRect
cvGetImageROI(IplImage* image)
ALIAS: cvGetROI = 1

CvMat*
cvGetMat(const CvArr* arr, CvMat* header, int* coi=NULL, int allowND=0)

#TBD# CvSparseNode* cvGetNextSparseNode(CvSparseMatIterator* matIterator)

MODULE = Cv	PACKAGE = Cv
int
cvGetOptimalDFTSize(int size0)

MODULE = Cv	PACKAGE = Cv::Arr
void
cvGetRawData(const CvArr* arr, SV* data, OUT int step, OUT CvSize roiSize)
INIT:
	uchar* p;
	int sz;
CODE:
	cvGetRawData(arr, &p, &step, &roiSize);
	sv_upgrade(data, SVt_PV);
	SvPV_set(data, (char*)p);
	sz = step * roiSize.height;
	if (CV_IS_IMAGE(arr)) {
		CvSize size = cvGetSize(arr);
		if (roiSize.height < size.height) {
			CvRect roi = cvGetImageROI((IplImage*)arr);
			sz = step * (roi.height - roi.y) - (step * roi.x) / size.width;
		}
	}
	SvCUR_set(data, sz);
	SvPOK_on(data);
	SvREADONLY_on(data); // XXXXX

#PERL# double cvGetReal1D(const CvArr* arr, int idx0)
#PERL# double cvGetReal2D(const CvArr* arr, int idx0, int idx1)
#PERL# double cvGetReal3D(const CvArr* arr, int idx0, int idx1, int idx2)

double
cvGetRealND(const CvArr* arr, int* idx)

CvMat*
cvGetRows(const CvArr* arr, CvMat* submat, int startRow, int endRow = NO_INIT, int deltaRow=1)
INIT:
	if (items <= 4) endRow = startRow + 1;
OUTPUT: RETVAL ST(0) = SvREFCNT_inc(ST(1));

CvSize
cvGetSize(const CvArr* arr)
ALIAS: cvSize = 1

CvMat*
cvGetSubRect(const CvArr* arr, CvMat* submat, CvRect rect)
OUTPUT: RETVAL ST(0) = SvREFCNT_inc(ST(1));

MODULE = Cv	PACKAGE = Cv
float
cvInvSqrt(float value)

MODULE = Cv	PACKAGE = Cv::Arr
void
cvInRange(const CvArr* src, const CvArr* lower, const CvArr* upper, CvArr* dst)
POSTCALL:
	ST(0) = ST(3);
	XSRETURN(1);

void
cvInRangeS(const CvArr* src, CvScalar lower, CvScalar upper, CvArr* dst)
POSTCALL:
	ST(0) = ST(3);
	XSRETURN(1);

int
cvIncRefData(CvArr* arr)

#TBD# IplImage* cvInitImageHeader(IplImage* image, CvSize size, int depth, int channels, int origin=0, int align=4)

#TBD# CvMat* cvInitMatHeader(CvMat* mat, int rows, int cols, int type, VOID* data=NULL, int step=CV_AUTOSTEP)

#TBD# CvMatND* cvInitMatNDHeader(CvMatND* mat, int dims, const int* sizes, int type, VOID* data=NULL)

#TBD# CvSparseNode* cvInitSparseMatIterator(const CvSparseMat* mat, CvSparseMatIterator* matIterator)

double
cvInv(const CvArr* src, CvArr* dst, int method=CV_LU)
ALIAS: cvInvert = 1

MODULE = Cv	PACKAGE = Cv
int
cvIsInf(double value)

int
cvIsNaN(double value)

MODULE = Cv	PACKAGE = Cv::Arr
void
cvLUT(const CvArr* src, CvArr* dst, const CvArr* lut)
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

void
cvLog(const CvArr* src, CvArr* dst)
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

double
cvMahalanobis(const CvArr* vec1, const CvArr* vec2, OUT CvArr* mat)

void
cvMax(const CvArr* src1, const CvArr* src2, CvArr* dst)
POSTCALL:
	ST(0) = ST(2);
	XSRETURN(1);

void
cvMaxS(const CvArr* src, double value, CvArr* dst)
POSTCALL:
	ST(0) = ST(2);
	XSRETURN(1);

void
cvMerge(const CvArr* src0, const CvArr* src1, const CvArr* src2, const CvArr* src3, CvArr* dst)
POSTCALL:
	ST(0) = ST(4);
	XSRETURN(1);

MODULE = Cv	PACKAGE = Cv::Arr
void
cvMin(const CvArr* src1, const CvArr* src2, CvArr* dst)
POSTCALL:
	ST(0) = ST(2);
	XSRETURN(1);

void
cvMinMaxLoc(const CvArr* arr, OUT double min_val, OUT double max_val, OUT CvPoint min_loc, OUT CvPoint max_loc, const CvArr* mask =NULL)

void
cvMinS(const CvArr* src, double value, CvArr* dst)
POSTCALL:
	ST(0) = ST(2);
	XSRETURN(1);


MODULE = Cv	PACKAGE = Cv
void
cvMixChannels(const CvArr** src, CvArr** dst, const int* fromTo)
C_ARGS: src, length(src), dst, length(dst), fromTo, length(fromTo)/2


MODULE = Cv	PACKAGE = Cv::Arr
void
cvMul(const CvArr* src1, const CvArr* src2, CvArr* dst, double scale=1)
POSTCALL:
	ST(0) = ST(2);
	XSRETURN(1);

void
cvMulSpectrums(const CvArr* src1, const CvArr* src2, CvArr* dst, int flags)
POSTCALL:
	ST(0) = ST(2);
	XSRETURN(1);

void
cvMulTransposed(const CvArr* src, CvArr* dst, int order, const CvArr* delta=NULL, double scale=1.0)
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

double
cvNorm(const CvArr* arr1, const CvArr* arr2=NULL, int normType=CV_L2, const CvArr* mask=NULL)

void
cvNormalize(const CvArr* src, CvArr* dst, double a = 1.0, double b = 0.0, int norm_type = CV_L2, const CvArr* mask = NULL)
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

void
cvNot(const CvArr* src, CvArr* dst)
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

void
cvOr(const CvArr* src1, const CvArr* src2, CvArr* dst, const CvArr* mask=NULL)
POSTCALL:
	ST(0) = ST(2);
	XSRETURN(1);

void
cvOrS(const CvArr* src, CvScalar value, CvArr* dst, const CvArr* mask=NULL)
POSTCALL:
	ST(0) = ST(2);
	XSRETURN(1);

void
cvPerspectiveTransform(const CvArr* src, CvArr* dst, const CvMat* mat)
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

void
cvPolarToCart(const CvArr* magnitude, const CvArr* angle, CvArr* x, CvArr* y, int angleInDegrees=0)

void
cvPow(const CvArr* src, CvArr* dst, double power)
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

#PERL# uchar* cvPtr1D(const CvArr* arr, int idx0, int* type=NULL)
#PERL# uchar* cvPtr2D(const CvArr* arr, int idx0, int idx1, int* type=NULL)
#PERL# uchar* cvPtr3D(const CvArr* arr, int idx0, int idx1, int idx2, int* type=NULL)

SV *
cvPtrND(const CvArr* arr, int* idx, type = NO_INIT, int createNode = 1, unsigned precalcHashval = NO_INIT)
INPUT:
	int &type = NO_INIT
CODE:
	uchar* s = (items <= 4)? cvPtrND(arr, idx, &type, createNode, NULL) :
		cvPtrND(arr, idx, &type, createNode, &precalcHashval);
	int sizes[CV_MAX_DIM];
	int dims = cvGetDims(arr, sizes), i, j, n;
	if (items >= 3) sv_setiv(ST(2), type);
	if (items >= 5) sv_setuv(ST(4), precalcHashval);
	for (i = 0; i < dims - 1; i++) if (sizes[i] > 1) break;
	for (j = dims - 1; j > i; j--) if (sizes[j] > 1) break;
 	n = sizes[j] - idx[i];
	RETVAL = newSVpvn_ro((const char*)s, n*CV_ELEM_SIZE(type));
OUTPUT:
	RETVAL

MODULE = Cv	PACKAGE = Cv
float
cvSqrt(float value)

CvRNG*
cvRNG(int64 seed = -1)
CODE:
	Newx(RETVAL, 1, CvRNG);
	*RETVAL = cvRNG(seed);
OUTPUT:
	RETVAL

MODULE = Cv	PACKAGE = Cv::RNG
void
cvReleaseRNG(CvRNG* rng)
ALIAS: DESTROY = 1
INIT:
	unbless(ST(0));
CODE:
	if (rng) safefree(rng);

void
cvRandArr(CvRNG* rng, CvArr* arr, int distType, CvScalar param1, CvScalar param2)
ALIAS: cvArr = 1
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

unsigned
cvRandInt(CvRNG* rng)
ALIAS: cvInt = 1

double
cvRandReal(CvRNG* rng)
ALIAS: cvReal = 1

MODULE = Cv	PACKAGE = Cv::Arr
void
cvReduce(const CvArr* src, CvArr* dst, int dim = -1, int op=CV_REDUCE_SUM)
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

void
cvReleaseData(CvArr* &arr)
INIT:
	unbless(ST(0));

MODULE = Cv	PACKAGE = Cv::Image
void
cvReleaseImage(IplImage* &image)
ALIAS: DESTROY = 1
INIT:
	unbless(ST(0));

MODULE = Cv	PACKAGE = Cv::Mat
void
cvReleaseMat(CvMat* &mat)
ALIAS: DESTROY = 1
INIT:
	unbless(ST(0));
	// if (!(mat && mat->refcount && *mat->refcount >= 0)) XSRETURN_EMPTY;

MODULE = Cv	PACKAGE = Cv::MatND
void
cvReleaseMatND(CvMatND* &mat)
ALIAS: DESTROY = 1
INIT:
	unbless(ST(0));
	// if (!(mat && mat->refcount && *mat->refcount >= 0)) XSRETURN_EMPTY;

MODULE = Cv	PACKAGE = Cv::SparseMat
void
cvReleaseSparseMat(CvSparseMat* &mat)
ALIAS: DESTROY = 1
INIT:
	unbless(ST(0));
	// if (!(mat && mat->refcount && *mat->refcount >= 0)) XSRETURN_EMPTY;

MODULE = Cv	PACKAGE = Cv::Arr
void
cvRepeat(const CvArr* src, CvArr* dst)
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);


void
cvResetImageROI(IplImage* image)
ALIAS: cvResetROI = 1

CvMat*
cvReshape(const CvArr* arr, CvMat* header, int newCn, int newRows=0)

CvArr*
cvReshapeMatND(const CvArr* arr, int sizeofHeader, CvArr* header, int newCn, int newDims, int* newSizes)


MODULE = Cv	PACKAGE = Cv
int
cvRound(double value)


MODULE = Cv	PACKAGE = Cv::Arr
void
cvScaleAdd(const CvArr* src1, CvScalar scale, const CvArr* src2, CvArr* dst)
POSTCALL:
	ST(0) = ST(3);
	XSRETURN(1);


void
cvSetImageCOI(IplImage* image, int coi)
ALIAS: cvSetCOI = 1

void
cvSetImageROI(IplImage* image, CvRect rect)
ALIAS: cvSetROI = 1
POSTCALL:
	XSRETURN(1);

void
cvSet(CvArr* arr, CvScalar value, const CvArr* mask=NULL)
ALIAS: cvFill = 1
POSTCALL:
	XSRETURN(1);

#PERL# void cvSet1D(CvArr* arr, int idx0, CvScalar value)
#PERL# void cvSet2D(CvArr* arr, int idx0, int idx1, CvScalar value)
#PERL# void cvSet3D(CvArr* arr, int idx0, int idx1, int idx2, CvScalar value)

void
cvSetND(CvArr* arr, int* idx, CvScalar value)
POSTCALL:
	XSRETURN(1);

void
cvSetData(CvArr* arr, SV* data, int step = CV_AUTOSTEP)
CODE:
	if (!SvPOK(data)) XSRETURN_UNDEF;
	cvSetData(arr, SvPV_nolen(data), step);
	XSRETURN(1);

void
cvSetIdentity(CvArr* mat, CvScalar value=cvRealScalar(1))
POSTCALL:
	XSRETURN(1);

#PERL# void cvSetReal1D(CvArr* arr, int idx0, double value)
#PERL# void cvSetReal2D(CvArr* arr, int idx0, int idx1, double value)
#PERL# void cvSetReal3D(CvArr* arr, int idx0, int idx1, int idx2, double value)

void
cvSetRealND(CvArr* arr, int* idx, double value)
POSTCALL:
	XSRETURN(1);

void
cvSetZero(CvArr* arr)
ALIAS: cvZero = 1
POSTCALL:
	XSRETURN(1);

int
cvSolve(const CvArr* src1, const CvArr* src2, CvArr* dst, int method=CV_LU)

int
cvSolveCubic(const CvMat* coeffs, CvMat* roots)


void
cvSplit(const CvArr* src, CvArr* dst0, CvArr* dst1 = NULL, CvArr* dst2 = NULL, CvArr* dst3 = NULL)

void
cvSub(const CvArr* src1, const CvArr* src2, CvArr* dst, const CvArr* mask=NULL)
POSTCALL:
	ST(0) = ST(2);
	XSRETURN(1);

void
cvSubRS(const CvArr* src, CvScalar value, CvArr* dst, const CvArr* mask=NULL)
POSTCALL:
	ST(0) = ST(2);
	XSRETURN(1);

void
cvSubS(const CvArr* src, CvScalar value, CvArr* dst, const CvArr* mask=NULL)
POSTCALL:
	ST(0) = ST(2);
	XSRETURN(1);

CvScalar
cvSum(const CvArr* arr)

void
cvSVBkSb(const CvArr* W, const CvArr* U, const CvArr* V, const CvArr* B, CvArr* X, int flags)

void
cvSVD(CvArr* A, CvArr* W, CvArr* U=NULL, CvArr* V=NULL, int flags=0)

CvScalar
cvTrace(const CvArr* mat)

void
cvTransform(const CvArr* src, CvArr* dst, const CvMat* transmat, const CvMat* shiftvec=NULL)
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

void
cvTranspose(const CvArr* src, CvArr* dst)
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

void
cvXor(const CvArr* src1, const CvArr* src2, CvArr* dst, const CvArr* mask=NULL)
POSTCALL:
	ST(0) = ST(2);
	XSRETURN(1);

void
cvXorS(const CvArr* src, CvScalar value, CvArr* dst, const CvArr* mask=NULL)
POSTCALL:
	ST(0) = ST(2);
	XSRETURN(1);

double
cvmGet(const CvMat* mat, int row, int col)

void
cvmSet(CvMat* mat, int row, int col, double value)


# ============================================================
#  core. The Core Functionality: Dynamic Structures
# ============================================================

MODULE = Cv	PACKAGE = Cv::MemStorage
# ====================
CvMemBlock*
bottom(CvMemStorage* stor)
CODE:
	RETVAL = stor->bottom;
OUTPUT:
	RETVAL

CvMemBlock*
top(CvMemStorage* stor)
CODE:
	RETVAL = stor->top;
OUTPUT:
	RETVAL

CvMemStorage*
parent(CvMemStorage* stor)
CODE:
	RETVAL = stor->parent;
OUTPUT:
	RETVAL

int
block_size(CvMemStorage* stor)
CODE:
	RETVAL = stor->block_size;
OUTPUT:
	RETVAL

int
free_space(CvMemStorage* stor)
CODE:
	RETVAL = stor->free_space;
OUTPUT:
	RETVAL


MODULE = Cv	PACKAGE = Cv::Seq
# ====================
int
flags(CvSeq* seq)
CODE:
	RETVAL = seq->flags;
OUTPUT:
	RETVAL

int
mat_type(CvSeq* seq)
ALIAS: type = 1
CODE:
	RETVAL = CV_MAT_TYPE(seq->flags);
OUTPUT:
	RETVAL

int
header_size(CvSeq* seq)
CODE:
	RETVAL = seq->header_size;
OUTPUT:
	RETVAL

CvSeq*
h_prev(CvSeq* seq)
CODE:
	RETVAL = seq->h_prev;
OUTPUT:
	RETVAL

CvSeq*
h_next(CvSeq* seq)
CODE:
	RETVAL = seq->h_next;
OUTPUT:
	RETVAL

CvSeq*
v_prev(CvSeq* seq)
CODE:
	RETVAL = seq->v_prev;
OUTPUT:
	RETVAL

CvSeq*
v_next(CvSeq* seq)
CODE:
	RETVAL = seq->v_next;
OUTPUT:
	RETVAL

int
total(CvSeq* seq)
CODE:
	RETVAL = seq->total;
OUTPUT:
	RETVAL

int
elem_size(CvSeq* seq)
CODE:
	RETVAL = seq->elem_size;
OUTPUT:
	RETVAL

VOID*
block_max(CvSeq* seq)
CODE:
	RETVAL = seq->block_max;
OUTPUT:
	RETVAL

VOID*
ptr(CvSeq* seq)
CODE:
	RETVAL = seq->ptr;
OUTPUT:
	RETVAL

int
delta_elems(CvSeq* seq)
CODE:
	RETVAL = seq->delta_elems;
OUTPUT:
	RETVAL

CvMemStorage*
storage(CvSeq* seq)
CODE:
	RETVAL = seq->storage;
OUTPUT:
	RETVAL


MODULE = Cv	PACKAGE = Cv::SeqReader
# ====================
VOID*
ptr(CvSeqReader* reader)
CODE:
	RETVAL = reader->ptr;
OUTPUT:
	RETVAL


MODULE = Cv	PACKAGE = Cv::String
# ====================
SV*
ptr(CvString str)
CODE:
	RETVAL = newSVpvn_ro(str.ptr, str.len);
OUTPUT:
	RETVAL

int
len(CvString str)
CODE:
	RETVAL = str.len;
OUTPUT:
	RETVAL


MODULE = Cv	PACKAGE = Cv
# ====================

#TBD# void cvClearGraph(CvGraph* graph)

MODULE = Cv	PACKAGE = Cv::MemStorage
void
cvClearMemStorage(CvMemStorage* storage)
ALIAS: cvClear = 1

MODULE = Cv	PACKAGE = Cv::Seq
void
cvClearSeq(CvSeq* seq)
ALIAS: cvClear = 1

#TBD# void cvClearSet(CvSet* setHeader)
#TBD# CvGraph* cvCloneGraph(const CvGraph* graph, CvMemStorage* storage)

CvSeq*
cvCloneSeq(const CvSeq* seq, CvMemStorage* storage=NULL)
ALIAS: cvClone = 1

MODULE = Cv	PACKAGE = Cv::MemStorage
CvMemStorage*
cvCreateChildMemStorage(CvMemStorage* parent)

#TBD# CvGraph* cvCreateGraph(int graph_flags, int header_size, int vtx_size, int edge_size, CvMemStorage* storage)
#TBD# CvGraphScanner* cvCreateGraphScanner(CvGraph* graph, CvGraphVtx* vtx=NULL, int mask=CV_GRAPH_ALL_ITEMS)

MODULE = Cv	PACKAGE = Cv
CvMemStorage*
cvCreateMemStorage(int blockSize=0)

CvSeq*
cvCreateSeq(int seqFlags, int headerSize, int elemSize, CvMemStorage* storage)

#TBD# CvSet* cvCreateSet(int setFlags, int headerSize, int elemSize, CvMemStorage* storage)


MODULE = Cv	PACKAGE = Cv::Arr
SV*
cvCvtSeqToArray(const CvSeq* seq, SV* elements, CvSlice slice=CV_WHOLE_SEQ)
INIT:
	int size = cvSliceLength(slice, seq) * seq->elem_size;
	sv_setpvn(elements, "", size);
	SvCUR_set(elements, size);
CODE:
	cvCvtSeqToArray(seq, SvPV_nolen(elements), slice);
OUTPUT:
	RETVAL ST(0) = SvREFCNT_inc(elements);

MODULE = Cv	PACKAGE = Cv::SeqWriter
CvSeq*
cvEndWriteSeq(CvSeqWriter* writer)


#TBD# CvGraphEdge* cvFindGraphEdge(const CvGraph* graph, int start_idx, int end_idx)
#TBD# CvGraphEdge* cvFindGraphEdgeByPtr(const CvGraph* graph, const CvGraphVtx* startVtx, const CvGraphVtx* endVtx)

void
cvFlushSeqWriter(CvSeqWriter* writer)

#TBD# CvGraphVtx* cvGetGraphVtx(CvGraph* graph, int vtx_idx)

MODULE = Cv	PACKAGE = Cv::Arr
SV *
cvGetSeqElem(const CvSeq* seq, int index)
CODE:
	RETVAL = newSVpvn_ro((char*)cvGetSeqElem(seq, index), seq->elem_size);
OUTPUT:
	RETVAL

void
cvSetSeqElem(const CvSeq* seq, int index, SV* elements)
INIT:
	char* dst;
CODE:
	dst = (char*)cvGetSeqElem(seq, index);
	if (dst && seq->elem_size == SvCUR(elements))
		memcpy(dst, SvPV_nolen(elements), seq->elem_size);


MODULE = Cv	PACKAGE = Cv::Seq::Seq

CvSeq*
cvGetSeqElem(const CvSeq* seq, int index)
CODE:
	RETVAL = *(CvSeq**)cvGetSeqElem(seq, index);
OUTPUT:
	RETVAL

void
cvSeqPush(CvSeq* seq, CvSeq* element)
C_ARGS:	seq, &element

MODULE = Cv	PACKAGE = Cv::SeqReader
int
cvGetSeqReaderPos(CvSeqReader* reader)

#TBD# CvSetElem* cvGetSetElem(const CvSet* setHeader, int index)
#TBD# int cvGraphAddEdge(CvGraph* graph, int start_idx, int end_idx, const CvGraphEdge* edge=NULL, CvGraphEdge** inserted_edge=NULL)
#TBD# int cvGraphAddEdgeByPtr(CvGraph* graph, CvGraphVtx* start_vtx, CvGraphVtx* end_vtx, const CvGraphEdge* edge=NULL, CvGraphEdge** inserted_edge=NULL)
#TBD# int cvGraphAddVtx(CvGraph* graph, const CvGraphVtx* vtx=NULL, CvGraphVtx** inserted_vtx=NULL)
#TBD# int cvGraphEdgeIdx(CvGraph* graph, CvGraphEdge* edge)
#TBD# void cvGraphRemoveEdge(CvGraph* graph, int start_idx, int end_idx)
#TBD# void cvGraphRemoveEdgeByPtr(CvGraph* graph, CvGraphVtx* start_vtx, CvGraphVtx* end_vtx)
#TBD# int cvGraphRemoveVtx(CvGraph* graph, int index)
#TBD# int cvGraphRemoveVtxByPtr(CvGraph* graph, CvGraphVtx* vtx)
#TBD# int cvGraphVtxDegree(const CvGraph* graph, int vtxIdx)
#TBD# int cvGraphVtxDegreeByPtr(const CvGraph* graph, const CvGraphVtx* vtx)
#TBD# int cvGraphVtxIdx(CvGraph* graph, CvGraphVtx* vtx)
#TBD# void cvInitTreeNodeIterator(CvTreeNodeIterator* tree_iterator, const VOID* first, int max_level)
#TBD# void cvInsertNodeIntoTree(VOID* node, VOID* parent, VOID* frame)


MODULE = Cv	PACKAGE = Cv
CvSeq*
cvMakeSeqHeaderForArray(int seq_type, int header_size, int elem_size, SV* elements, SV* seq, SV* block)
INIT:
	sv_setpvn(seq, "", sizeof(CvSeq));
	SvCUR_set(seq, sizeof(CvSeq));
	sv_setpvn(block, "", sizeof(CvSeqBlock));
	SvCUR_set(block, sizeof(CvSeqBlock));
C_ARGS:
	seq_type, header_size, elem_size, SvPV_nolen(elements), SvLEN(elements)/elem_size, (CvSeq*)SvPV_nolen(seq), (CvSeqBlock*)SvPV_nolen(block)


MODULE = Cv	PACKAGE = Cv::MemStorage
VOID*
cvMemStorageAlloc(CvMemStorage* storage, size_t size)

CvString
cvMemStorageAllocString(CvMemStorage* storage, SV* ptr, int len=-1)
ALIAS: cvAllocString = 1
C_ARGS:
	storage, SvPV_nolen(ptr), len >= 0? len : SvCUR(ptr)


#TBD# int cvNextGraphItem(CvGraphScanner* scanner)
#TBD# VOID* cvNextTreeNode(CvTreeNodeIterator* tree_iterator)
#TBD# VOID* cvPrevTreeNode(CvTreeNodeIterator* tree_iterator)
#TBD# void cvReleaseGraphScanner(CvGraphScanner* &scanner)

void
cvReleaseMemStorage(CvMemStorage* &storage)
ALIAS: DESTROY = 1
INIT:
	unbless(ST(0));

void
cvRestoreMemStoragePos(CvMemStorage* storage, CvMemStoragePos pos)
C_ARGS:	storage, &pos

void
cvSaveMemStoragePos(const CvMemStorage* storage, OUT CvMemStoragePos pos)
	
#TBD# int cvSeqElemIdx(const CvSeq* seq, const VOID* element, CvSeqBlock** block=NULL)

MODULE = Cv	PACKAGE = Cv::Arr
void
cvSeqInvert(CvSeq* seq)

void
cvSeqInsert(CvSeq* seq, int beforeIndex, element = NO_INIT)
C_ARGS:	seq, beforeIndex, items == 3? SvPV_nolen(ST(2)) : NULL

void
cvSeqInsertSlice(CvSeq* seq, int beforeIndex, const CvArr* fromArr)

void
cvSeqPopMulti(CvSeq* seq, SV* elements, int count, int in_front = 0)
INIT:
	sv_setpvn(elements, "", count*seq->elem_size);
	SvCUR_set(elements, count*seq->elem_size);
C_ARGS:
	seq, SvPV_nolen(elements), count, in_front

void
cvSeqPushMulti(CvSeq* seq, SV* elements, int count, int in_front = 0)
C_ARGS:	seq, SvPV_nolen(elements), count, in_front

SV *
cvSeqPop(CvSeq* seq)
INIT:
	if (seq->total == 0) XSRETURN_UNDEF;
	RETVAL = newSVpvn("", seq->elem_size);
	SvCUR_set(RETVAL, seq->elem_size);
CODE:
	cvSeqPop(seq, SvPV_nolen(RETVAL));
OUTPUT:
	RETVAL

SV *
cvSeqPopFront(CvSeq* seq)
INIT:
	if (seq->total == 0) XSRETURN_UNDEF;
	RETVAL = newSVpvn("", seq->elem_size);
	SvCUR_set(RETVAL, seq->elem_size);
CODE:
	cvSeqPopFront(seq, SvPV_nolen(RETVAL));
OUTPUT:
	RETVAL

void
cvSeqPush(CvSeq* seq, SV* element)
C_ARGS:	seq, SvPV_nolen(element)

void
cvSeqPushFront(CvSeq* seq, SV* element)
C_ARGS:	seq, SvPV_nolen(element)

void
cvSeqRemove(CvSeq* seq, int index)

void
cvSeqRemoveSlice(CvSeq* seq, CvSlice slice)

#TBD# char* cvSeqSearch(CvSeq* seq, const VOID* elem, CvCmpFunc func, int is_sorted, int* elem_idx, VOID* userdata=NULL)

CvSeq*
cvSeqSlice(const CvSeq* seq, CvSlice slice, CvMemStorage* storage=NULL, int copy_data=0)

#TBD# void cvSeqSort(CvSeq* seq, CvCmpFunc func, VOID* userdata=NULL)
#TBD# int cvSetAdd(CvSet* setHeader, CvSetElem* elem=NULL, CvSetElem** inserted_elem=NULL)
#TBD# CvSetElem* cvSetNew(CvSet* setHeader)
#TBD# void cvSetRemove(CvSet* setHeader, int index)
#TBD# void cvSetRemoveByPtr(CvSet* setHeader, VOID* elem)
#TBD# void cvSetSeqBlockSize(CvSeq* seq, int deltaElems)
#TBD# void cvSetSeqReaderPos(CvSeqReader* reader, int index, int is_relative=0)

MODULE = Cv	PACKAGE = Cv

#PERL# CvSlice cvSlice(int start_index, int end_index)

MODULE = Cv	PACKAGE = Cv::Arr
int
cvSliceLength(const CvSeq* seq, CvSlice slice)
C_ARGS: slice, seq

void
cvStartAppendToSeq(CvSeq* seq, CvSeqWriter* writer)

void
cvStartReadSeq(const CvSeq* seq, OUT CvSeqReader* reader, int reverse = 0)
INIT:
	Newx(reader, 1, CvSeqReader);
C_ARGS:
	seq, reader, reverse

MODULE = Cv	PACKAGE = Cv
void
cvStartWriteSeq(int seq_flags, int header_size, int elem_size, CvMemStorage* storage, CvSeqWriter* writer)

#TBD# CvSeq* cvTreeToNodeSeq(const VOID* first, int header_size, CvMemStorage* storage)

MODULE = Cv	PACKAGE = Cv::SeqReader
void
cvReleaseSeqReader(CvSeqReader* reader)
ALIAS: DESTROY = 1
INIT:
	unbless(ST(0));
CODE:
	if (reader) safefree(reader);

void
cvNextSeqElem(CvSeqReader* reader)
CODE:
	if (CV_IS_SEQ(reader->seq)) {
		CV_NEXT_SEQ_ELEM(reader->seq->elem_size, *reader);
	} else if (CV_IS_SET((CvSet*)reader->seq)) {
		CV_NEXT_SEQ_ELEM(((CvSet*)reader->seq)->elem_size, *reader);
	}

SV *
cvReadSeqElem(CvSeqReader* reader)
CODE:
	if (CV_IS_SEQ(reader->seq)) {
		RETVAL = newSVpvn_ro((const char*)reader->ptr, reader->seq->elem_size);
		CV_NEXT_SEQ_ELEM(reader->seq->elem_size, *reader);
	} else if (CV_IS_SET((CvSet*)reader->seq)) {
		RETVAL = newSVpvn_ro((const char*)reader->ptr, ((CvSet*)reader->seq)->elem_size);
		CV_NEXT_SEQ_ELEM(((CvSet*)reader->seq)->elem_size, *reader);
	} else {
		RETVAL = newSVpvn("", 0);
	}
OUTPUT:
	RETVAL


# ============================================================
#  core. The Core Functionality: Drawing Functions
# ============================================================

MODULE = Cv	PACKAGE = Cv::Arr
# ====================
void
cvCircle(CvArr* img, CvPoint center, int radius, CvScalar color, int thickness=1, int lineType=8, int shift=0)
POSTCALL:
	XSRETURN(1);

MODULE = Cv	PACKAGE = Cv
int
cvClipLine(CvSize imgSize, CvPoint& pt1, CvPoint& pt2)
OUTPUT:
	pt1
	pt2

MODULE = Cv	PACKAGE = Cv::Arr
void
cvDrawContours(CvArr *img, CvSeq* contour, CvScalar external_color, CvScalar hole_color, int max_level, int thickness=1, int line_type=8, CvPoint offset=cvPoint(0, 0));

void
cvEllipse(CvArr* img, CvPoint center, CvSize axes, double angle, double start_angle, double end_angle, CvScalar color, int thickness=1, int lineType=8, int shift=0)
POSTCALL:
	XSRETURN(1);

void
cvEllipseBox(CvArr* img, CvBox2D box, CvScalar color, int thickness=1, int lineType=8, int shift=0)
INIT:
POSTCALL:
	XSRETURN(1);

void
cvFillConvexPoly(CvArr* img, CvPoint* pts, CvScalar color, int lineType=8, int shift=0)
C_ARGS:	img, pts, length(pts), color, lineType, shift
POSTCALL:
	XSRETURN(1);

void
cvFillPoly(CvArr* img, CvPoint** pts, CvScalar color, int lineType=8, int shift=0)
C_ARGS: img, pts, length(inner_pts), length(pts), color, lineType, shift
POSTCALL:
	XSRETURN(1);

MODULE = Cv	PACKAGE = Cv
void
cvGetTextSize(const char* textString, const CvFont* font, OUT CvSize textSize, OUT int baseline)

CvFont*
cvInitFont(int fontFace, double hscale, double vscale, double shear=0, int thickness=1, int lineType=8)
INIT:
	Newx(RETVAL, 1, CvFont);
#if _CV_VERSION() == _VERSION(2,1,0)
	if (lineType & CV_AA) lineType |= 1; /* XXXXX */
#endif
CODE:
	cvInitFont(RETVAL, fontFace, hscale, vscale, shear, thickness, lineType);
OUTPUT:
	RETVAL

MODULE = Cv	PACKAGE = Cv::Font
void
cvReleaseFont(CvFont* font)
ALIAS: DESTROY = 1
INIT:
	unbless(ST(0));
CODE:
	safefree(font);

#TBD# int cvInitLineIterator(const CvArr* image, CvPoint pt1, CvPoint pt2, CvLineIterator* line_iterator, int connectivity=8, int left_to_right=0)

MODULE = Cv	PACKAGE = Cv::Arr
void
cvLine(CvArr* img, CvPoint pt1, CvPoint pt2, CvScalar color, int thickness=1, int lineType=8, int shift=0)
POSTCALL:
	XSRETURN(1);

void
cvPolyLine(CvArr* img, CvPoint** pts, int is_closed, CvScalar color, int thickness = 1, int line_type = 8, int shift = 0)
C_ARGS: img, pts, length(inner_pts), length(pts), is_closed, color, thickness, line_type, shift
POSTCALL:
	XSRETURN(1);

void
cvPutText(CvArr* img, const char* text, CvPoint org, const CvFont* font, CvScalar color)
POSTCALL:
	XSRETURN(1);

void
cvRectangle(CvArr* img, CvPoint pt1, CvPoint pt2, CvScalar color, int thickness=1, int lineType=8, int shift=0)
POSTCALL:
	XSRETURN(1);

#PERL# CvScalar CV_RGB(double r, double g, double b)

# ============================================================
#  core. The Core Functionality: XML/YAML Persistence
# ============================================================

MODULE = Cv	PACKAGE = Cv::TypeInfo
# ====================
const char*
type_name(CvTypeInfo* info)
CODE:
	RETVAL = info->type_name;
OUTPUT:
	RETVAL

MODULE = Cv	PACKAGE = Cv::StringHashNode
# ====================
unsigned
hashval(CvStringHashNode *np)
CODE:
	RETVAL = np->hashval;
OUTPUT:
	RETVAL

CvString
str(CvStringHashNode *np)
CODE:
	RETVAL = np->str;
OUTPUT:
	RETVAL

CvStringHashNode*
next(CvStringHashNode *np)
CODE:
	RETVAL = np->next;
OUTPUT:
	RETVAL


MODULE = Cv	PACKAGE = Cv
# ====================
VOID*
cvClone(const VOID* structPtr)

MODULE = Cv	PACKAGE = Cv::FileStorage
void
cvEndWriteStruct(CvFileStorage* fs)

MODULE = Cv	PACKAGE = Cv
CvTypeInfo*
cvFindType(const char* typeName)

CvTypeInfo*
cvFirstType()

MODULE = Cv	PACKAGE = Cv::FileStorage
CvFileNode*
cvGetFileNode(CvFileStorage* fs, CvFileNode* map, const CvStringHashNode* key, int createMissing=0)

CvFileNode*
cvGetFileNodeByName(const CvFileStorage* fs, const CvFileNode* map, const char* name)

MODULE = Cv	PACKAGE = Cv::FileNode
const char*
cvGetFileNodeName(const CvFileNode* node)


MODULE = Cv	PACKAGE = Cv::FileStorage
CvStringHashNode*
cvGetHashedKey(CvFileStorage* fs, const char* name, int len=-1, int createMissing=0)

CvFileNode*
cvGetRootFileNode(const CvFileStorage* fs, int stream_index=0)


MODULE = Cv	PACKAGE = Cv
VOID*
cvLoad(const char* filename, CvMemStorage* storage = NULL, const char* name = NULL, realName = NO_INIT)
INPUT:
	const char* &realName = NO_INIT
CODE:
	RETVAL = cvLoad(filename, storage, name, &realName);
	if (items >= 3) sv_setpvn((SV*)ST(3), realName, strlen(realName));
OUTPUT:
	RETVAL

CvFileStorage*
cvOpenFileStorage(const char* filename, int flags, CvMemStorage* memstorage = NULL, const char* encoding=NULL)
CODE:
	RETVAL = cvOpenFileStorage(filename, memstorage, flags
#if _CV_VERSION() >= _VERSION(2,3,0)
		, encoding
#endif
		);
OUTPUT:
	RETVAL

MODULE = Cv	PACKAGE = Cv::FileStorage
VOID*
cvRead(CvFileStorage* fs, CvFileNode* node, attributes = NO_INIT)
PREINIT:
	CvAttrList* null = NULL;
C_ARGS:
	fs, node, null

#PERL# VOID* cvReadByName(CvFileStorage* fs, const CvFileNode* map, const char* name, CvAttrList* attributes=NULL)

MODULE = Cv	PACKAGE = Cv::FileNode
int
cvReadInt(const CvFileNode* node, int defaultValue=0)

MODULE = Cv	PACKAGE = Cv::FileStorage
int
cvReadIntByName(const CvFileStorage* fs, const CvFileNode* map, const char* name, int defaultValue=0)

void
cvReadRawData(const CvFileStorage* fs, const CvFileNode* src, VOID* dst, const char* dt)

void
cvReadRawDataSlice(const CvFileStorage* fs, CvSeqReader* reader, int count, VOID* dst, const char* dt)


MODULE = Cv	PACKAGE = Cv::FileNode
double
cvReadReal(const CvFileNode* node, double defaultValue=0.0)


MODULE = Cv	PACKAGE = Cv::FileStorage
double
cvReadRealByName(const CvFileStorage* fs, const CvFileNode* map, const char* name, double defaultValue=0.0)


MODULE = Cv	PACKAGE = Cv::FileNode
const char*
cvReadString(const CvFileNode* node, const char* defaultValue=NULL)


MODULE = Cv	PACKAGE = Cv::FileStorage
const char*
cvReadStringByName(const CvFileStorage* fs, const CvFileNode* map, const char* name, const char* defaultValue=NULL)


#TBD# void cvRegisterType(const CvTypeInfo* info)

MODULE = Cv	PACKAGE = Cv
void
cvRelease(VOID* &structPtr)
INIT:
	unbless(ST(0));

MODULE = Cv	PACKAGE = Cv::FileStorage
void
cvReleaseFileStorage(CvFileStorage* &fs)
ALIAS: DESTROY = 1
INIT:
	unbless(ST(0));

MODULE = Cv	PACKAGE = Cv
void
cvSave(const char* filename, const VOID* structPtr, const char* name=NULL, const char* comment=NULL, CvAttrList attributes=cvAttrList(NULL, NULL))
INIT:
	if (items >= 3 && SvREF0(ST(2))) name = NULL;
	if (items >= 4 && SvREF0(ST(3))) comment = NULL;

MODULE = Cv	PACKAGE = Cv::FileStorage
void
cvStartNextStream(CvFileStorage* fs)

void
cvStartReadRawData(const CvFileStorage* fs, const CvFileNode* src, CvSeqReader* reader)

void
cvStartWriteStruct(CvFileStorage* fs, const char* name, int struct_flags, const char* typeName=NULL, CvAttrList attributes=cvAttrList(NULL, NULL))
INIT:
	if (items >= 4 && SvREF0(ST(3))) typeName = NULL;


MODULE = Cv	PACKAGE = Cv
CvTypeInfo*
cvTypeOf(const VOID* structPtr)

#TBD# void cvUnregisterType(const char* typeName)


MODULE = Cv	PACKAGE = Cv::FileStorage
void
cvWrite(CvFileStorage* fs, const char* name, const VOID* ptr, CvAttrList attributes=cvAttrList(NULL, NULL))

void
cvWriteComment(CvFileStorage* fs, const char* comment, int eolComment)

void
cvWriteFileNode(CvFileStorage* fs, const char* new_node_name, const CvFileNode* node, int embed)

void
cvWriteInt(CvFileStorage* fs, const char* name, int value)

void
cvWriteRawData(CvFileStorage* fs, const VOID* src, int len, const char* dt)

void
cvWriteReal(CvFileStorage* fs, const char* name, double value)

void
cvWriteString(CvFileStorage* fs, const char* name, const char* str, int quote=0)


# ============================================================
#  core. The Core Functionality: Clustering
# ============================================================

MODULE = Cv	PACKAGE = Cv::Arr
int
cvKMeans2(const CvArr* samples, int nclusters, CvArr* labels, CvTermCriteria termcrit, int attempts=1, CvRNG* rng=0, int flags=0, CvArr* centers=0, double* compactness=0)
CODE:
	RETVAL = 
#if _CV_VERSION() < _VERSION(2,0,0)
	0;
#endif
	cvKMeans2(samples, nclusters, labels, termcrit
#if _CV_VERSION() >= _VERSION(2,0,0)
		, attempts, rng, flags, centers, compactness
#endif
		);
OUTPUT:
	RETVAL

#TBD# int cvSeqPartition(const CvSeq* seq, CvMemStorage* storage, CvSeq** labels, CvCmpFunc is_equal, VOID* userdata)


# ============================================================
#  core. The Core Functionality: Utility and System Functions and Macros
# ============================================================

MODULE = Cv	PACKAGE = Cv
# ====================

#PERL# int cvGetErrStatus(void)
#PERL# void cvSetErrStatus(int status)
#PERL# int cvGetErrMode(void)
#PERL# int cvSetErrMode(int mode)
#PERL# CvErrorCallback cvRedirectError(CvErrorCallback error_handler, void* userdata=NULL, void** prevUserdata=NULL)
#PERL# void cvError(int status, const char* func_name, const char* err_msg, const char* filename, int line)

const char*
cvErrorStr(int status)

#TBD# int cvNulDevReport(int status, const char* func_name, const char* err_msg, const char* file_name, int line, VOID* userdata)
#TBD# int cvStdErrReport(int status, const char* func_name, const char* err_msg, const char* file_name, int line, VOID* userdata)
#TBD# int cvGuiBoxReport(int status, const char* func_name, const char* err_msg, const char* file_name, int line, VOID* userdata)

VOID*
cvAlloc(size_t size)

void
cvFree(VOID* &ptr)

#if _CV_VERSION() >= _VERSION(2,3,0)

int
cvCheckHardwareSupport(int feature)

#endif

int
cvGetNumThreads()

int
cvGetThreadNum()

int64
cvGetTickCount()

double
cvGetTickFrequency()

#TBD# int cvRegisterModule(const CvModuleInfo* moduleInfo)

#TBD# void cvGetModuleInfo(const char* moduleName, const char** version, const char** loadedAddonPlugins)

int
cvUseOptimized(int onoff)

#TBD# void cvSetMemoryManager(CvAllocFunc allocFunc=NULL, CvFreeFunc freeFunc=NULL, VOID* userdata=NULL)

#TBD# void cvSetIPLAllocators(Cv_iplCreateImageHeader create_header, Cv_iplAllocateImageData allocate_data, Cv_iplDeallocate deallocate, Cv_iplCreateROI create_roi, Cv_iplCloneImage clone_image)


# ============================================================
#  imgproc. Image Processing: Image Filtering
# ============================================================

MODULE = Cv	PACKAGE = Cv::Arr
void
cvCopyMakeBorder(const CvArr* src, CvArr* dst, CvPoint offset, int bordertype, CvScalar value=cvScalarAll(0))
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);


MODULE = Cv	PACKAGE = Cv
IplConvKernel*
cvCreateStructuringElementEx(int cols, int rows, int anchorX, int anchorY, int shape, int* values=NULL)


MODULE = Cv	PACKAGE = Cv::Arr
void
cvDilate(const CvArr* src, CvArr* dst, IplConvKernel* element=NULL, int iterations=1)
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

void
cvErode(const CvArr* src, CvArr* dst, IplConvKernel* element=NULL, int iterations=1)
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

void
cvFilter2D(const CvArr* src, CvArr* dst, const CvMat* kernel, CvPoint anchor=cvPoint(-1, -1))
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

void
cvLaplace(const CvArr* src, CvArr* dst, int apertureSize=3)
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

void
cvMorphologyEx(const CvArr* src, CvArr* dst, CvArr* temp, IplConvKernel* element, int operation, int iterations=1)
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

void
cvPyrDown(const CvArr* src, CvArr* dst, int filter=CV_GAUSSIAN_5x5)
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

void
cvPyrUp(const CvArr* src, CvArr* dst, int filter=CV_GAUSSIAN_5x5)
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);


MODULE = Cv	PACKAGE = Cv::ConvKernel
void
cvReleaseStructuringElement(IplConvKernel* &element)
ALIAS: DESTROY = 1


MODULE = Cv	PACKAGE = Cv::Arr
void
cvSmooth(const CvArr* src, CvArr* dst, int smoothType=CV_GAUSSIAN, int param1=3, int param2=0, double param3=0, double param4=0)
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

void
cvSobel(const CvArr* src, CvArr* dst, int xorder, int yorder, int apertureSize=3)
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

# ============================================================
#  imgproc. Image Processing: Geometric Image Transformations
# ============================================================

MODULE = Cv	PACKAGE = Cv
CvMat*
cv2DRotationMatrix(CvPoint2D32f center, double angle, double scale, CvMat* mapMatrix)
ALIAS: cvGetRotationMatrix2D = 1
OUTPUT: RETVAL ST(0) = SvREFCNT_inc(ST(3));

MODULE = Cv	PACKAGE = Cv
CvMat*
cvGetAffineTransform(const CvPoint2D32f* src, const CvPoint2D32f* dst, CvMat* mapMatrix)
OUTPUT: RETVAL ST(0) = SvREFCNT_inc(ST(2));

CvMat*
cvGetPerspectiveTransform(const CvPoint2D32f* src, const CvPoint2D32f* dst, CvMat* mapMatrix)
OUTPUT: RETVAL ST(0) = SvREFCNT_inc(ST(2));

MODULE = Cv	PACKAGE = Cv::Arr
void
cvGetQuadrangleSubPix(const CvArr* src, CvArr* dst, const CvMat* mapMatrix)
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

void
cvGetRectSubPix(const CvArr* src, CvArr* dst, CvPoint2D32f center)
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

void
cvLogPolar(const CvArr* src, CvArr* dst, CvPoint2D32f center, double M, int flags=CV_INTER_LINEAR + CV_WARP_FILL_OUTLIERS)
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

#if _CV_VERSION() >= _VERSION(2,0,0)

void
cvLinearPolar(const CvArr* src, CvArr* dst, CvPoint2D32f center, double maxRadius, int flags = CV_INTER_LINEAR + CV_WARP_FILL_OUTLIERS);
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

#endif

void
cvRemap(const CvArr* src, CvArr* dst, const CvArr* mapx, const CvArr* mapy, int flags=CV_INTER_LINEAR + CV_WARP_FILL_OUTLIERS, CvScalar fillval=cvScalarAll(0))
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

void
cvResize(const CvArr* src, CvArr* dst, int interpolation=CV_INTER_LINEAR)
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

void
cvWarpAffine(const CvArr* src, CvArr* dst, const CvMat* mapMatrix, int flags=CV_INTER_LINEAR + CV_WARP_FILL_OUTLIERS, CvScalar fillval=cvScalarAll(0))
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

void
cvWarpPerspective(const CvArr* src, CvArr* dst, const CvMat* mapMatrix, int flags=CV_INTER_LINEAR + CV_WARP_FILL_OUTLIERS, CvScalar fillval=cvScalarAll(0))
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

# ============================================================
#  imgproc. Image Processing: Miscellaneous Image Transformations
# ============================================================

void
cvAdaptiveThreshold(const CvArr* src, CvArr* dst, double maxValue, int adaptive_method=CV_ADAPTIVE_THRESH_MEAN_C, int thresholdType=CV_THRESH_BINARY, int blockSize=3, double param1=5)
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

void
cvCvtColor(const CvArr* src, CvArr* dst, int code)
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

void
cvDistTransform(const CvArr* src, CvArr* dst, int distanceType=CV_DIST_L2, int maskSize=3, float* mask=NULL, CvArr* labels=NULL, labelType=NO_INIT)
INPUT:
	int labelType = NO_INIT
INIT:
#if _CV_VERSION() >= _VERSION(2,4,0)
	if (items < 7)
		labelType = CV_DIST_LABEL_CCOMP;
	else
		labelType = (int)SvIV(ST(7));
#endif
CODE:
	cvDistTransform(src, dst, distanceType, maskSize, mask, labels
#if _CV_VERSION() >= _VERSION(2,4,0)
		, labelType
#endif
		);
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

void
cvEqualizeHist(const CvArr* src, CvArr* dst);
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

void
cvFloodFill(CvArr* image, CvPoint seed_point, CvScalar new_val, CvScalar lo_diff=cvScalarAll(0), CvScalar up_diff=cvScalarAll(0), comp = NO_INIT, int flags=4, CvArr* mask=NULL)
INPUT:
	CvConnectedComp &comp = NO_INIT
OUTPUT:
	comp

void
cvWatershed(const CvArr* image, CvArr* markers)
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

void
cvInpaint(const CvArr* src, const CvArr* mask, CvArr* dst, double inpaintRadius, int flags)
POSTCALL:
	ST(0) = ST(2);
	XSRETURN(1);

void
cvIntegral(const CvArr* image, CvArr* sum, CvArr* sqsum=NULL, CvArr* tiltedSum=NULL)
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

void
cvPyrMeanShiftFiltering(const CvArr* src, CvArr* dst, double sp, double sr, int max_level=1, CvTermCriteria termcrit= cvTermCriteria(CV_TERMCRIT_ITER + CV_TERMCRIT_EPS, 5, 1))
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

#C# void cvPyrSegmentation(IplImage* src, IplImage* dst, CvMemStorage* storage, comp, int level, double threshold1, double threshold2)

void
cvPyrSegmentation(CvArr* src, CvArr* dst, CvMemStorage* storage, comp, int level, double threshold1, double threshold2)
INPUT:
	CvSeq* &comp = NO_INIT
C_ARGS:
	(IplImage*)src, (IplImage*)dst, storage, &comp, level, threshold1, threshold2
POSTCALL:
	sv_setref_pv(ST(3), "Cv::Seq", (VOID*)comp);
	ST(0) = ST(1);
	XSRETURN(1);


# BUG: cvThreshold() updates the parameter threshold if thresholdType
# is CV_THRESH_OTSU.  It looks like perl magic.  So, you can use
# Threshold() is as follows:
# my $bin = cvThreshold($src, $dst, my $thresh, 255, CV_THRESH_OTSU);

NO_OUTPUT double
cvThreshold(const CvArr* src, CvArr* dst, double threshold, double maxValue, int thresholdType)
POSTCALL:
	if (thresholdType & CV_THRESH_OTSU) {
		if (!SvREADONLY(ST(2))) sv_setnv(ST(2), RETVAL);
	}
	ST(0) = ST(1);
	XSRETURN(1);


# ============================================================
#  imgproc. Image Processing: Structural Analysis and Shape Descriptors
# ============================================================

MODULE = Cv	PACKAGE = Cv::Arr
CvSeq*
cvApproxChains(CvSeq* src_seq, CvMemStorage* storage, int method=CV_CHAIN_APPROX_SIMPLE, double parameter=0, int minimal_perimeter=0, int recursive=0)


MODULE = Cv	PACKAGE = Cv::Arr
CvSeq*
cvApproxPoly(const VOID* src_seq, int header_size, CvMemStorage* storage, int method, double parameter, int parameter2=0)

double
cvArcLength(const VOID* curve, CvSlice slice=CV_WHOLE_SEQ, int isClosed=-1)
ALIAS: cvContourPerimeter = 1

CvRect
cvBoundingRect(CvArr* points, int update=0)


MODULE = Cv	PACKAGE = Cv

void
cvBoxPoints(CvBox2D box, pts)
INPUT:
	CvPoint2D32f* pts = NO_INIT
INIT:
	int length(pts) = 4;
	pts = (CvPoint2D32f*)alloca(sizeof(CvPoint2D32f) * length(pts));
	sv_setsv(ST(1), newRV((SV*)newAV())); // XXXXX
OUTPUT:
	pts

MODULE = Cv	PACKAGE = Cv::Arr

#C# float cvCalcEMD2(const CvArr* signature1, const CvArr* signature2, int distance_type, CvDistanceFunction distance_func=NULL, const CvArr* cost_matrix=NULL, CvArr* flow=NULL, float* lower_bound=NULL, VOID* userdata=NULL)

float
cvCalcEMD2(const CvArr* signature1, const CvArr* signature2, int distance_type, SV* distance_func=NULL, const CvArr* cost_matrix=NULL, CvArr* flow=NULL, float* lower_bound=NULL, SV* userdata=NULL)
INIT:
	if (distance_func) {
		Perl_croak(aTHX_ "Cv::cvCalcEMD2: can't support distance_func");
	}
	if (userdata) {
		if (!SvREF0(userdata))
			Perl_croak(aTHX_ "Cv::cvCalcEMD2: can't support userdata");
		userdata = NULL;
	}
C_ARGS:	signature1, signature2, distance_type, (CvDistanceFunction) distance_func, cost_matrix, flow, lower_bound, (VOID*) userdata

int
cvCheckContourConvexity(const CvArr* contour)

double
cvContourArea(const CvArr* contour, CvSlice slice=CV_WHOLE_SEQ, int oriented=0)
CODE:
	RETVAL = cvContourArea(contour, slice=CV_WHOLE_SEQ
#if _CV_VERSION() >= _VERSION(2,0,0)
		, oriented
#endif
		);
OUTPUT:
	RETVAL

#if defined __cplusplus || _CV_VERSION() <= _VERSION(2,1,0)

MODULE = Cv	PACKAGE = Cv::ContourTree
CvSeq*
cvContourFromContourTree(const CvContourTree* tree, CvMemStorage* storage, CvTermCriteria criteria)

#endif

MODULE = Cv	PACKAGE = Cv::Arr
CvSeq*
cvConvexHull2(const CvArr* input, VOID* storage=NULL, int orientation=CV_CLOCKWISE, int return_points=1)

CvSeq*
cvConvexityDefects(const CvArr* contour, const CvArr* convexhull, CvMemStorage* storage=NULL)


#if defined __cplusplus || _CV_VERSION() <= _VERSION(2,1,0)

MODULE = Cv	PACKAGE = Cv::Arr
CvContourTree*
cvCreateContourTree(const CvSeq* contour, CvMemStorage* storage, double threshold)

#endif

MODULE = Cv	PACKAGE = Cv::ContourScanner
CvSeq*
cvEndFindContours(CvContourScanner &scanner)

MODULE = Cv	PACKAGE = Cv::Arr
int
cvFindContours(CvArr* image, CvMemStorage* storage, OUT CvSeq* first_contour, int header_size=sizeof(CvContour), int mode=CV_RETR_LIST, int method=CV_CHAIN_APPROX_SIMPLE, CvPoint offset=cvPoint(0, 0))

MODULE = Cv	PACKAGE = Cv::ContourScanner
CvSeq*
cvFindNextContour(CvContourScanner scanner)

MODULE = Cv	PACKAGE = Cv::Arr
CvBox2D
cvFitEllipse2(const CvArr* points)
ALIAS: cvFitEllipse = 1

void
cvFitLine(const CvArr* points, int dist_type, double param, double reps, double aeps, line)
INPUT:
	float* line = NO_INIT
INIT:
	int type = CV_IS_SEQ(points)? CV_MAT_TYPE(((CvSeq*)points)->flags) :
		cvGetElemType(points);
	int cn = CV_MAT_CN(type);
	int length(line) = cn * 2;
	line = (float*)alloca(sizeof(float)*6);
	if (SvTYPE(ST(5)) == SVt_NULL) {
		sv_setsv(ST(5), newRV((SV*)newAV()));
	}
OUTPUT:
	line

MODULE = Cv	PACKAGE = Cv::Moments
double
cvGetCentralMoment(CvMoments* moments, int x_order, int y_order)

CvHuMoments*
cvGetHuMoments(CvMoments* moments)
INIT:
	Newx(RETVAL, 1, CvHuMoments);
CODE:
	cvGetHuMoments(moments, RETVAL);
OUTPUT:
	RETVAL

double
cvGetNormalizedCentralMoment(CvMoments* moments, int x_order, int y_order)

double
cvGetSpatialMoment(CvMoments* moments, int x_order, int y_order)


MODULE = Cv	PACKAGE = Cv::Moments
# ====================
double
m00(const CvMoments* moments)
CODE:
	RETVAL = moments->m00;
OUTPUT:
	RETVAL

double
m10(const CvMoments* moments)
CODE:
	RETVAL = moments->m10;
OUTPUT:
	RETVAL

double
m01(const CvMoments* moments)
CODE:
	RETVAL = moments->m01;
OUTPUT:
	RETVAL

double
m20(const CvMoments* moments)
CODE:
	RETVAL = moments->m20;
OUTPUT:
	RETVAL

double
m11(const CvMoments* moments)
CODE:
	RETVAL = moments->m11;
OUTPUT:
	RETVAL

double
m02(const CvMoments* moments)
CODE:
	RETVAL = moments->m02;
OUTPUT:
	RETVAL

double
m30(const CvMoments* moments)
CODE:
	RETVAL = moments->m30;
OUTPUT:
	RETVAL

double
m21(const CvMoments* moments)
CODE:
	RETVAL = moments->m21;
OUTPUT:
	RETVAL

double
m12(const CvMoments* moments)
CODE:
	RETVAL = moments->m12;
OUTPUT:
	RETVAL

double
m03(const CvMoments* moments)
CODE:
	RETVAL = moments->m03;
OUTPUT:
	RETVAL

double
inv_sqrt_m00(const CvMoments* moments)
CODE:
	RETVAL = moments->inv_sqrt_m00;
OUTPUT:
	RETVAL

MODULE = Cv	PACKAGE = Cv::HuMoments
# ====================
void
cvReleaseHuMoments(CvHuMoments* hu_moments)
ALIAS: DESTROY = 1
INIT:
	unbless(ST(0));
CODE:
	safefree(hu_moments);

MODULE = Cv	PACKAGE = Cv::HuMoments
# ====================
double
hu1(const CvHuMoments* hu_moments)
CODE:
	RETVAL = hu_moments->hu1;
OUTPUT:
	RETVAL

double
hu2(const CvHuMoments* hu_moments)
CODE:
	RETVAL = hu_moments->hu2;
OUTPUT:
	RETVAL

double
hu3(const CvHuMoments* hu_moments)
CODE:
	RETVAL = hu_moments->hu3;
OUTPUT:
	RETVAL

double
hu4(const CvHuMoments* hu_moments)
CODE:
	RETVAL = hu_moments->hu4;
OUTPUT:
	RETVAL

double
hu5(const CvHuMoments* hu_moments)
CODE:
	RETVAL = hu_moments->hu5;
OUTPUT:
	RETVAL

double
hu6(const CvHuMoments* hu_moments)
CODE:
	RETVAL = hu_moments->hu6;
OUTPUT:
	RETVAL

double
hu7(const CvHuMoments* hu_moments)
CODE:
	RETVAL = hu_moments->hu7;
OUTPUT:
	RETVAL


MODULE = Cv	PACKAGE = Cv		
# ====================

#if defined __cplusplus || _CV_VERSION() <= _VERSION(2,1,0)

MODULE = Cv	PACKAGE = Cv::ContourTree
double
cvMatchContourTrees(const CvContourTree* tree1, const CvContourTree* tree2, int method, double threshold)

#endif

MODULE = Cv	PACKAGE = Cv::Arr
double
cvMatchShapes(const VOID* object1, const VOID* object2, int method, double parameter=0)

CvBox2D
cvMinAreaRect2(const CvArr* points, CvMemStorage* storage=NULL)
ALIAS: cvMinAreaRect = 1

CvSeq*
cvHoughCircles(CvArr* image, CvMemStorage* circleStorage, int method, double dp, double minDist, double param1=100, double param2=100, int minRadius=0, int maxRadius=0)

int
cvMinEnclosingCircle(const CvArr* points, OUT CvPoint2D32f center, OUT float radius)

CvMoments*
cvMoments(const CvArr* arr, int binary=0)
INIT:
	Newx(RETVAL, 1, CvMoments);
CODE:
	int type = cvGetElemType(arr);
	int channels = CV_MAT_CN(type);
	int coi = cvGetImageCOI((IplImage*)arr);
	if (channels == 1 || coi != 0) {
		cvMoments(arr, RETVAL, binary);
	} else {
		cvSetImageCOI((IplImage*)arr, 1);
		cvMoments(arr, RETVAL, binary);
		cvSetImageCOI((IplImage*)arr, coi);
	}
OUTPUT:
	RETVAL


MODULE = Cv	PACKAGE = Cv::Moments
void
cvReleaseMoments(CvMoments* moments)
ALIAS: DESTROY = 1
INIT:
	unbless(ST(0));
CODE:
	safefree(moments);


MODULE = Cv	PACKAGE = Cv::Arr
double
cvPointPolygonTest(const CvArr* contour, CvPoint2D32f pt, int measure_dist)

CvSeq*
cvPointSeqFromMat(const CvArr* mat, int seq_kind, SV* contour_header, SV* block)
INIT:
	sv_setpvn(contour_header, "", sizeof(CvContour));
	SvCUR_set(contour_header, sizeof(CvContour));
	sv_setpvn(block, "", sizeof(CvSeqBlock));
	SvCUR_set(block, sizeof(CvSeqBlock));
C_ARGS:
	seq_kind, mat, (CvContour*)SvPV_nolen(contour_header), (CvSeqBlock*)SvPV_nolen(block)
OUTPUT:
	RETVAL bless(ST(0), "Cv::Seq::Point", RETVAL);

MODULE = Cv	PACKAGE = Cv::ChainPtReader
CvPoint
cvReadChainPoint(CvChainPtReader* reader)


MODULE = Cv	PACKAGE = Cv::Arr
CvContourScanner
cvStartFindContours(CvArr* image, CvMemStorage* storage, int header_size=sizeof(CvContour), int mode=CV_RETR_LIST, int method=CV_CHAIN_APPROX_SIMPLE, CvPoint offset=cvPoint(0, 0))


MODULE = Cv	PACKAGE = Cv::Chain
void
cvStartReadChainPoints(CvChain* chain, CvChainPtReader* reader)


MODULE = Cv	PACKAGE = Cv::ContourScanner
void
cvSubstituteContour(CvContourScanner scanner, CvSeq* new_contour)


# ============================================================
#  imgproc. Image Processing: Motion Analysis and Object Tracking
# ============================================================

MODULE = Cv	PACKAGE = Cv::Arr
void
cvAcc(const CvArr* image, CvArr* sum, const CvArr* mask=NULL)
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

void
cvMultiplyAcc(const CvArr* image1, const CvArr* image2, CvArr* acc, const CvArr* mask=NULL)

void
cvRunningAvg(const CvArr* image, CvArr* acc, double alpha, const CvArr* mask=NULL)

void
cvSquareAcc(const CvArr* image, CvArr* sqsum, const CvArr* mask=NULL)


# ============================================================
#  imgproc. Image Processing: Feature Detection
# ============================================================

void
cvCanny(const CvArr* image, CvArr* edges, double threshold1, double threshold2, int aperture_size=3)
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

void
cvCornerEigenValsAndVecs(const CvArr* image, CvArr* eigenvv, int blockSize, int aperture_size=3)
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

void
cvCornerHarris(const CvArr* image, CvArr* harris_dst, int blockSize, int aperture_size=3, double k=0.04)
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

void
cvCornerMinEigenVal(const CvArr* image, CvArr* eigenval, int blockSize, int aperture_size=3)
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

void
cvFindCornerSubPix(const CvArr* image, CvPoint2D32f* corners, CvSize win, CvSize zero_zone, CvTermCriteria criteria)
C_ARGS:
	image, corners, length(corners), win, zero_zone, criteria
OUTPUT:
	corners

void
cvGoodFeaturesToTrack(const CvArr* image, CvArr* eigImage, CvArr* tempImage, corners, int cornerCount, double qualityLevel, double minDistance, const CvArr* mask=NULL, int blockSize=3, int useHarris=0, double k=0.04)
INPUT:
	CvPoint2D32f* corners = NO_INIT
INIT:
	int length(corners) = cornerCount;
	corners = (CvPoint2D32f*)alloca(sizeof(CvPoint2D32f) * cornerCount);
C_ARGS:
	image, eigImage, tempImage, corners, &length(corners), qualityLevel, minDistance, mask, blockSize, useHarris, k
OUTPUT:
	corners

CvSeq*
cvHoughLines2(CvArr* image, VOID* storage, int method, double rho, double theta, int threshold, double param1=0, double param2=0)

void
cvPreCornerDetect(const CvArr* image, CvArr* corners, int apertureSize=3)

int
cvSampleLine(const CvArr* image, CvPoint pt1, CvPoint pt2, VOID* buffer, int connectivity=8)


# ============================================================
#  imgproc. Image Processing: Object Detection
# ============================================================

void
cvMatchTemplate(const CvArr* image, const CvArr* templ, CvArr* result, int method)
POSTCALL:
	ST(0) = ST(2);
	XSRETURN(1);

# ============================================================
#  features2d. Feature Detection and Descriptor Extraction:
#    Feature detection and description
# ============================================================

MODULE = Cv		PACKAGE = Cv
CvSURFParams
cvSURFParams(double hessianThreshold, int extended = 0)

MODULE = Cv	PACKAGE = Cv::Arr
void
cvExtractSURF(const CvArr* image, const CvArr* mask, keypoints, descriptors, CvMemStorage* storage, CvSURFParams params, int useProvidedKeyPts=0)
INPUT:
	CvSeq* keypoints = NO_INIT
	CvSeq* descriptors = NO_INIT
INIT:
	CvSeq** descriptors_ptr = (CvSeq**) 0;
	keypoints = (CvSeq*) 0;
	descriptors = (CvSeq*) 0;
#if _CV_VERSION() >= _VERSION(2,0,0)
	if (useProvidedKeyPts) {
		if (sv_isobject(ST(2)) && sv_derived_from(ST(2), "Cv::Seq")) {
			keypoints = INT2PTR(CvSeq *, SvIV((SV*)SvRV(ST(2))));
		} else {
			Perl_croak(aTHX_ "%s is not of type %s in %s",
					"keypoints", "CvSeq *", "Cv::cvExtractSURF");
		}
	}
#endif
	if (SvREF0(ST(3))) {
		descriptors_ptr = (CvSeq**) 0;
	} else {
		descriptors_ptr = &descriptors;
	}
CODE:
	cvExtractSURF(image, mask, &keypoints, descriptors_ptr, storage, params
#if _CV_VERSION() >= _VERSION(2,0,0)
		, useProvidedKeyPts
#endif
		);
	sv_setref_pv(ST(2), "Cv::Seq::SURFPoint", (void*)keypoints);
	SvSETMAGIC(ST(2));
	if (descriptors_ptr) {
		sv_setref_pv(ST(3), "Cv::Seq::SURFDescriptor", (void*)descriptors);
		SvSETMAGIC(ST(3));
	}


#if HAVE_cvExtractMSER

MODULE = Cv		PACKAGE = Cv
CvMSERParams
cvMSERParams(int delta = 5, int minArea = 60, int maxArea = 14400, float maxVariation = 0.25f, float minDiversity = 0.2f, int maxEvolution = 200, double areaThreshold = 1.01, double minMargin = 0.003, int edgeBlurSize = 5)
CODE:
	RETVAL.delta = delta;
	RETVAL.minArea = minArea;
	RETVAL.maxArea = maxArea;
	RETVAL.maxVariation = maxVariation;
	RETVAL.minDiversity = minDiversity;
	RETVAL.maxEvolution = maxEvolution;
	RETVAL.areaThreshold = areaThreshold;
	RETVAL.minMargin = minMargin;
	RETVAL.edgeBlurSize = edgeBlurSize;
OUTPUT:
	RETVAL

MODULE = Cv	PACKAGE = Cv::Arr
void
cvExtractMSER(CvArr* img, CvArr* mask, OUT CvSeq* contours, CvMemStorage* storage, CvMSERParams params)
OUTPUT:
	contours sv_setref_pv(ST(2), "Cv::Seq::Seq", (void*)contours);

#endif

#if _CV_VERSION() >= _VERSION(2,0,0)
# if _CV_VERSION() >= _VERSION(2,2,0)

CvStarDetectorParams
cvStarDetectorParams(int maxSize = 45, int responseThreshold = 30, int lineThresholdProjected = 10, int lineThresholdBinarized = 8, int suppressNonmaxSize = 5)

# else

CvStarDetectorParams
cvStarDetectorParams(int maxSize = 45, int responseThreshold = 30, int lineThresholdProjected = 10, int lineThresholdBinarized = 8)

# endif

CvSeq*
cvGetStarKeypoints(const CvArr* img, CvMemStorage* storage, CvStarDetectorParams params=cvStarDetectorParams())

#endif

# ============================================================
#  objdetect. Object Detection: Cascade Classification:
#    Haar Feature-based Cascade Classifier for Object Detection
# ============================================================

MODULE = Cv	PACKAGE = Cv
# ====================
CvHaarClassifierCascade*
cvLoadHaarClassifierCascade(const char* directory, CvSize orig_window_size)


MODULE = Cv	PACKAGE = Cv::Arr
CvSeq*
cvHaarDetectObjects(const CvArr* image, CvHaarClassifierCascade* cascade, CvMemStorage* storage, double scaleFactor=1.1, int minNeighbors=3, int flags=0, CvSize minSize=cvSize(0,0), CvSize maxSize=cvSize(0,0))
CODE:
	RETVAL = cvHaarDetectObjects(image, cascade, storage, scaleFactor, minNeighbors, flags, minSize
#if _CV_VERSION() >= _VERSION(2,2,0)
	, maxSize
#endif
	);
OUTPUT:
	RETVAL

MODULE = Cv	PACKAGE = Cv::HaarClassifierCascade
void
cvSetImagesForHaarClassifierCascade(CvHaarClassifierCascade* cascade, const CvArr* sum, const CvArr* sqsum, const CvArr* tilted_sum, double scale)

void
cvReleaseHaarClassifierCascade(CvHaarClassifierCascade* &cascade)
ALIAS: DESTROY = 1
INIT:
	unbless(ST(0));

int
cvRunHaarClassifierCascade(CvHaarClassifierCascade* cascade, CvPoint pt, int start_stage=0)


# ============================================================
#  video. Video Analysis: Motion Analysis and Object Tracking
# ============================================================

MODULE = Cv	PACKAGE = Cv::Arr
# ====================
double
cvCalcGlobalOrientation(const CvArr* orientation, const CvArr* mask, const CvArr* mhi, double timestamp, double duration)

void
cvCalcMotionGradient(const CvArr* mhi, CvArr* mask, CvArr* orientation, double delta1, double delta2, int apertureSize=3)
ALIAS: Cv::cvCalcMotionGradient = 1

void
cvCalcOpticalFlowBM(const CvArr* prev, const CvArr* curr, CvSize blockSize, CvSize shiftSize, CvSize max_range, int usePrevious, CvArr* velx, CvArr* vely)
ALIAS: Cv::cvCalcOpticalFlowBM = 1

void
cvCalcOpticalFlowHS(const CvArr* prev, const CvArr* curr, int usePrevious, CvArr* velx, CvArr* vely, double lambda, CvTermCriteria criteria)
ALIAS: Cv::cvCalcOpticalFlowHS = 1

void
cvCalcOpticalFlowLK(const CvArr* prev, const CvArr* curr, CvSize winSize, CvArr* velx, CvArr* vely)
ALIAS: Cv::cvCalcOpticalFlowLK = 1

void
cvCalcOpticalFlowPyrLK(const CvArr* prev, const CvArr* curr, CvArr* prevPyr, CvArr* currPyr, const CvPoint2D32f* prevFeatures, currFeatures, CvSize winSize, int level, status, track_error, CvTermCriteria criteria, int flags)
ALIAS: Cv::cvCalcOpticalFlowPyrLK = 1
INPUT:
	CvPoint2D32f* currFeatures = NO_INIT
	tiny* status = NO_INIT
	float* track_error = NO_INIT
INIT:
	int count = length(prevFeatures);
	int length(currFeatures) = count;
	currFeatures = (CvPoint2D32f*)alloca(sizeof(CvPoint2D32f) * count);
	int length(status) = count;
	status = (char*)alloca(sizeof(char) * count);
	int length(track_error) = count;
	track_error = (float*)alloca(sizeof(float) * count);
C_ARGS:
	prev, curr, prevPyr, currPyr, prevFeatures, currFeatures, length(prevFeatures), winSize, level, status, track_error, criteria, flags
OUTPUT:
	currFeatures
	status
	track_error

#if _CV_VERSION() >= _VERSION(2,0,0)

void
cvCalcOpticalFlowFarneback(const CvArr* prev, const CvArr* next, CvArr* flow, double pyr_scale, int levels, int winsize, int iterations, int poly_n, double poly_sigma, int flags);
ALIAS: Cv::cvCalcOpticalFlowFarneback = 1

#endif

int
cvCamShift(const CvArr* prob_image, CvRect window, CvTermCriteria criteria, comp, box)
ALIAS: Cv::cvCamShift = 1
INPUT:
	CvConnectedComp &comp = NO_INIT
	CvBox2D &box = NO_INIT
OUTPUT:
	comp
	box


MODULE = Cv	PACKAGE = Cv
CvConDensation*
cvCreateConDensation(int dynam_params, int measure_params, int sample_count)

MODULE = Cv	PACKAGE = Cv::ConDensation
void
cvConDensInitSampleSet(CvConDensation* condens, CvMat* lower_bound, CvMat* upper_bound)

void
cvReleaseConDensation( CvConDensation*& condens )
ALIAS: DESTROY = 1


MODULE = Cv	PACKAGE = Cv::Kalman
# ====================
int
MP(CvKalman* kalman)
CODE:
	RETVAL = kalman->MP;
OUTPUT:
	RETVAL

int
DP(CvKalman* kalman)
CODE:
	RETVAL = kalman->DP;
OUTPUT:
	RETVAL

int
CP(CvKalman* kalman)
CODE:
	RETVAL = kalman->CP;
OUTPUT:
	RETVAL

CvMat*
state_pre(CvKalman* kalman)
CODE:
	RETVAL = kalman->state_pre;
OUTPUT:
	RETVAL bless(ST(0), "Cv::Mat::Ghost", RETVAL);

CvMat*
state_post(CvKalman* kalman)
CODE:
	RETVAL = kalman->state_post;
OUTPUT:
	RETVAL bless(ST(0), "Cv::Mat::Ghost", RETVAL);

CvMat*
transition_matrix(CvKalman* kalman)
CODE:
	RETVAL = kalman->transition_matrix;
OUTPUT:
	RETVAL bless(ST(0), "Cv::Mat::Ghost", RETVAL);

CvMat*
control_matrix(CvKalman* kalman)
CODE:
	RETVAL = kalman->control_matrix;
OUTPUT:
	RETVAL bless(ST(0), "Cv::Mat::Ghost", RETVAL);

CvMat*
measurement_matrix(CvKalman* kalman)
CODE:
	RETVAL = kalman->measurement_matrix;
OUTPUT:
	RETVAL bless(ST(0), "Cv::Mat::Ghost", RETVAL);

CvMat*
process_noise_cov(CvKalman* kalman)
CODE:
	RETVAL = kalman->process_noise_cov;
OUTPUT:
	RETVAL bless(ST(0), "Cv::Mat::Ghost", RETVAL);

CvMat*
measurement_noise_cov(CvKalman* kalman)
CODE:
	RETVAL = kalman->measurement_noise_cov;
OUTPUT:
	RETVAL bless(ST(0), "Cv::Mat::Ghost", RETVAL);

CvMat*
error_cov_pre(CvKalman* kalman)
CODE:
	RETVAL = kalman->error_cov_pre;
OUTPUT:
	RETVAL bless(ST(0), "Cv::Mat::Ghost", RETVAL);

CvMat*
gain(CvKalman* kalman)
CODE:
	RETVAL = kalman->gain;
OUTPUT:
	RETVAL bless(ST(0), "Cv::Mat::Ghost", RETVAL);

CvMat*
error_cov_post(CvKalman* kalman)
CODE:
	RETVAL = kalman->error_cov_post;
OUTPUT:
	RETVAL bless(ST(0), "Cv::Mat::Ghost", RETVAL);


MODULE = Cv	PACKAGE = Cv
# ====================
CvKalman*
cvCreateKalman(int dynam_params, int measure_params, int control_params=0)

MODULE = Cv	PACKAGE = Cv::Kalman
const CvMat*
cvKalmanCorrect(CvKalman* kalman, const CvMat* measurement)
OUTPUT: RETVAL bless(ST(0), "Cv::Mat::Ghost", RETVAL);

const CvMat*
cvKalmanPredict(CvKalman* kalman, const CvMat* control=NULL)
OUTPUT: RETVAL bless(ST(0), "Cv::Mat::Ghost", RETVAL);

MODULE = Cv	PACKAGE = Cv::Arr
int
cvMeanShift(const CvArr* prob_image, CvRect window, CvTermCriteria criteria, comp)
INPUT:
	CvConnectedComp &comp = NO_INIT
OUTPUT:
	comp

MODULE = Cv	PACKAGE = Cv::Kalman
void
cvReleaseKalman(CvKalman* &kalman)
ALIAS: DESTROY = 1
INIT:
	unbless(ST(0));

MODULE = Cv	PACKAGE = Cv::Arr
CvSeq*
cvSegmentMotion(const CvArr* mhi, CvArr* seg_mask, CvMemStorage* storage, double timestamp, double seg_thresh)

void
cvSnakeImage(const IplImage* image, CvPoint* points, int length, float* alpha, float* beta, float* gamma, int coeff_usage, CvSize win, CvTermCriteria criteria, int calc_gradient=1)

void
cvUpdateMotionHistory(const CvArr* silhouette, CvArr* mhi, double timestamp, double duration)


# ============================================================
#  highgui. High-level GUI and Media I/O: User Interface
# ============================================================

MODULE = Cv	PACKAGE = Cv::Arr
# ====================
void
cvConvertImage(const CvArr* src, CvArr* dst, int flags=0)

MODULE = Cv	PACKAGE = Cv
int
cvCreateTrackbar(const char* trackbarName, const char* windowName, SV* value, int count, SV* onChange = NULL)
PREINIT:
	callback_t* callback; 
	HV* Cv_TRACKBAR;
	SV** q; AV* av; SV* sv;
INIT:
	if (!(Cv_TRACKBAR = get_hv("Cv::TRACKBAR", 0))) {
		Perl_croak(aTHX_ "Cv::cvCreateTrackbar: can't get \%Cv::TRACKBAR");
	}
	RETVAL = -1;
CODE:
	Newx(callback, 1, callback_t);
	callback->callback = 0;
	if (onChange && SvROK(onChange) && SvTYPE(SvRV(onChange)) == SVt_PVCV) {
		SvREFCNT_inc(callback->callback = (SV*)SvRV(onChange));
	}
	callback->u.t.value = 0;
	callback->u.t.lastpos = callback->u.t.pos = 0;
	if (SvOK(value) && SvTYPE(value) == SVt_IV) {
		SvREFCNT_inc(callback->u.t.value = value);
		callback->u.t.lastpos = callback->u.t.pos = SvIV(value);
	}
	RETVAL = cvCreateTrackbar(trackbarName,	windowName,
				&callback->u.t.pos, count, cb_trackbar);
	q = hv_fetch(Cv_TRACKBAR, windowName, strlen(windowName), 0);
	if (q && SvROK(*q) && SvTYPE(SvRV(*q)) == SVt_PVAV) { SV* sv;
		av = (AV*)SvRV(*q);
	} else if (!q) {
		av = newAV();
		hv_store(Cv_TRACKBAR, windowName, strlen(windowName),
			newRV_inc(sv_2mortal((SV*)av)), 0);
	} else {
		Perl_croak(aTHX_ "Cv::cvCreateTrackbar: Cv::TRACKBAR was broken");
	}
	av_push(av, newSViv(PTR2IV(callback)));
OUTPUT:
	RETVAL

void
cvDestroyAllWindows()
INIT:
	delete_all_callback("Cv::TRACKBAR");
	delete_all_callback("Cv::MOUSE");


void
cvDestroyWindow(const char* name)
INIT:
	delete_win_callback(name, "Cv::TRACKBAR");
	delete_win_callback(name, "Cv::MOUSE");

int
cvGetTrackbarPos(const char* trackbarName, const char* windowName)

CvWindow*
cvGetWindowHandle(const char* name)

MODULE = Cv	PACKAGE = Cv
const char*
cvGetWindowName(CvWindow* windowHandle)

#TBD# int cvInitSystem(int argc, char** argv)

int
cvInitSystem(AV* argv)
CODE:
	if (av_len(argv) >= 0) {
		char **av = (char**)alloca(sizeof(char*) * (av_len(argv) + 2)); int ac;
		if (av == NULL) XSRETURN_UNDEF;
		for (ac = 0; ac <= av_len(argv); ac++) {
			av[ac] = SvPV_nolen((SV*)(*av_fetch(argv, ac, 0)));
		}
		av[ac++] = 0;
		RETVAL = cvInitSystem(ac, av);
	} else {
		RETVAL = cvInitSystem(0, NULL);
	}
OUTPUT:
	RETVAL


MODULE = Cv	PACKAGE = Cv
void
cvMoveWindow(const char* name, int x, int y)

int
cvNamedWindow(const char* name, int flags = CV_WINDOW_AUTOSIZE)

void
cvResizeWindow(const char* name, int width, int height)

#C# void cvSetMouseCallback(const char* windowName, CvMouseCallback onMouse = NULL, VOID* param=NULL)

void
cvSetMouseCallback(const char* windowName, SV* onMouse = NO_INIT, SV* userdata = NO_INIT)
PREINIT:
	callback_t* callback;
	HV* Cv_MOUSE;
	SV** q; AV* av; SV* sv;
INIT:
	if (items <= 1) onMouse = (SV*)0;
	if (items <= 2) userdata = (SV*)0;
	if (!(Cv_MOUSE = get_hv("Cv::MOUSE", 0))) {
		Perl_croak(aTHX_ "Cv::cvSetMouseCallback: can't get \%Cv::MOUSE");
	}
CODE:
	Newx(callback, 1, callback_t);
	callback->callback = 0;
	if (onMouse && SvROK(onMouse) && SvTYPE(SvRV(onMouse)) == SVt_PVCV) {
		SvREFCNT_inc(callback->callback = (SV*)SvRV(onMouse));
	}
	callback->u.m.userdata = 0;
	if (userdata) {
		SvREFCNT_inc(callback->u.m.userdata = userdata);
	}
	q = hv_fetch(Cv_MOUSE, windowName, strlen(windowName), 0);
	if (q && SvROK(*q) && SvTYPE(SvRV(*q)) == SVt_PVAV) { SV* sv;
		av = (AV*)SvRV(*q);
		cvSetMouseCallback(windowName, NULL, NULL);
		delete_callback(av);
	} else if (!q) {
		av = newAV();
		hv_store(Cv_MOUSE, windowName, strlen(windowName),
			newRV_inc(sv_2mortal((SV*)av)), 0);
	} else {
		Perl_croak(aTHX_ "Cv::cvSetMouseCallback: Cv::MOUSE was broken");
	}
	if (onMouse) {
		av_push(av, newSViv(PTR2IV(callback)));
		cvSetMouseCallback(windowName, cb_mouse, callback);
	}

void
cvSetTrackbarPos(const char* trackbarName, const char* windowName, int pos)

void
cvShowImage(const char* name, const CvArr* image)


MODULE = Cv	PACKAGE = Cv
int
cvWaitKey(int delay=0)

# ============================================================
#  highgui. High-level GUI and Media I/O: Reading and Writing Images and Video
# ============================================================

IplImage*
cvLoadImage(const char* filename, int iscolor=CV_LOAD_IMAGE_COLOR)

CvMat*
cvLoadImageM(const char* filename, int iscolor=CV_LOAD_IMAGE_COLOR)


#if _CV_VERSION() >= _VERSION(2,0,0)

int
cvSaveImage(const char* filename, const CvArr* image, const int* params=0)

#else

int
cvSaveImage(const char* filename, const CvArr* image)

#endif


MODULE = Cv	PACKAGE = Cv::Arr

#if _CV_VERSION() >= _VERSION(2,0,0)

CvMat*
cvEncodeImage(const CvArr* arr, const char* ext, int* params)
CODE:
    int i = length(params) & ~1;
#if _CV_VERSION() >= _VERSION(2,4,4)
	if (params) params[i] = 0;
	RETVAL = cvEncodeImage(ext, arr, params);
#else
#ifdef __cplusplus
    cv::Mat img = cv::cvarrToMat(arr);
    if (CV_IS_IMAGE(arr) && ((const IplImage*)arr)->origin == IPL_ORIGIN_BL) {
        cv::Mat temp;
        cv::flip(img, temp, 0);
        img = temp;
    }
    cv::vector<uchar> buf;
    bool code = cv::imencode(ext, img, buf,
        i > 0 ? std::vector<int>(params, params + i) : std::vector<int>());
    if (!code) XSRETURN_UNDEF;
    RETVAL = cvCreateMat(1, (int)buf.size(), CV_8U);
    memcpy(RETVAL->data.ptr, &buf[0], buf.size());
#else
	if (params) params[i] = 0;
	RETVAL = cvEncodeImage(ext, arr, params);
#endif
#endif
OUTPUT:
	RETVAL

#C# IplImage* cvDecodeImage(const CvMat* buf, int iscolor=CV_LOAD_IMAGE_COLOR)
#C# CvMat* cvDecodeImageM(const CvMat* buf, int iscolor=CV_LOAD_IMAGE_COLOR)

MODULE = Cv	PACKAGE = Cv
IplImage*
cvDecodeImage(SV* buf, int iscolor=CV_LOAD_IMAGE_COLOR)
ALIAS: Cv::Arr::cvDecodeImage = 1
INIT:
	RETVAL = (IplImage*)0;
CODE:
	if (SvROK(buf) && sv_isobject(buf) && sv_derived_from(buf, "Cv::Arr")) {
		IV tmp = SvIV((SV*)SvRV(buf));
		const CvArr* arr = INT2PTR(const CvArr*, tmp); CvMat m;
		RETVAL = cvDecodeImage(cvGetMat(arr, &m, NULL, 1), iscolor);
	} else if (SvPOK(buf)) {
		CvMat m; int rows = 1, cols = SvCUR(buf);
		cvInitMatHeader(&m, rows, cols, CV_8UC1, SvPV_nolen(buf), cols);
		RETVAL = cvDecodeImage(&m, iscolor);
	} else {
		if (SvROK(buf))
			Perl_croak(aTHX_ "unsuported reference SvTYPE = %d\n", SvTYPE(SvRV(buf)));
		else
			Perl_croak(aTHX_ "unsuported SvTYPE = %d\n", SvTYPE(buf));
	}
OUTPUT:
	RETVAL

CvMat*
cvDecodeImageM(SV* buf, int iscolor=CV_LOAD_IMAGE_COLOR)
ALIAS: Cv::Arr::cvDecodeImageM = 1
INIT:
	RETVAL = (CvMat*)0;
CODE:
	if (SvROK(buf) && sv_isobject(buf) && sv_derived_from(buf, "Cv::Arr")) {
		IV tmp = SvIV((SV*)SvRV(buf));
		const CvArr* arr = INT2PTR(const CvArr*, tmp); CvMat m;
		RETVAL = cvDecodeImageM(cvGetMat(arr, &m, NULL, 1), iscolor);
	} else if (SvPOK(buf)) {
		CvMat m; int rows = 1, cols = SvCUR(buf);
		cvInitMatHeader(&m, rows, cols, CV_8UC1, SvPV_nolen(buf), cols);
		RETVAL = cvDecodeImageM(&m, iscolor);
	} else {
		if (SvROK(buf))
			Perl_croak(aTHX_ "unsuported reference SvTYPE = %d\n", SvTYPE(SvRV(buf)));
		else
			Perl_croak(aTHX_ "unsuported SvTYPE = %d\n", SvTYPE(buf));
	}
OUTPUT:
	RETVAL

#endif

MODULE = Cv	PACKAGE = Cv
CvCapture*
cvCaptureFromCAM(int index)
ALIAS: cvCreateCameraCapture = 1

CvCapture*
cvCaptureFromFile(const char* filename)
ALIAS: cvCreateFileCapture = 1
ALIAS: cvCaptureFromAVI = 2

MODULE = Cv	PACKAGE = Cv::Capture
double
cvGetCaptureProperty(CvCapture* capture, int property_id)

int
cvGrabFrame(CvCapture* capture)

IplImage*
cvQueryFrame(CvCapture* capture)
OUTPUT: RETVAL bless(ST(0), "Cv::Image::Ghost", RETVAL);

void
cvReleaseCapture(CvCapture* &capture)
ALIAS: DESTROY = 1
INIT:
	unbless(ST(0));

IplImage*
cvRetrieveFrame(CvCapture* capture, int streamIdx=0)
CODE:
	cvRetrieveFrame(capture
#if _CV_VERSION() >= _VERSION(2,0,0)
		, streamIdx
#endif
		);
OUTPUT:
	RETVAL bless(ST(0), "Cv::Image::Ghost", RETVAL);

int
cvSetCaptureProperty(CvCapture* capture, int property_id, double value)

MODULE = Cv	PACKAGE = Cv
CvVideoWriter*
cvCreateVideoWriter(const char* filename, int fourcc, double fps, CvSize frame_size, int is_color=1)


MODULE = Cv	PACKAGE = Cv::VideoWriter
void
cvReleaseVideoWriter(CvVideoWriter* &writer)
ALIAS: DESTROY = 1
INIT:
	unbless(ST(0));

int
cvWriteFrame(CvVideoWriter* writer, const IplImage* image)

# ============================================================
#  calib3d. Camera Calibration, Pose Estimation and Stereo: Camera
#   Calibration and 3d Reconstruction
# ============================================================

MODULE = Cv		PACKAGE = Cv

void
cvCalcImageHomography(float* line, CvPoint3D32f* center, float* intrinsic, float* homography)

MODULE = Cv	PACKAGE = Cv::Arr
double
cvCalibrateCamera2(const CvMat* objectPoints, const CvMat* imagePoints, const CvMat* pointCounts, CvSize imageSize, CvMat* cameraMatrix, CvMat* distCoeffs, CvMat* rvecs=NULL, CvMat* tvecs=NULL, int flags=0, CvTermCriteria term_crit = cvTermCriteria(CV_TERMCRIT_ITER+CV_TERMCRIT_EPS,30,DBL_EPSILON))
ALIAS: Cv::cvCalibrateCamera2 = 1
CODE:
	RETVAL = 
#if _CV_VERSION() < _VERSION(2,0,0)
	0;
#endif
	cvCalibrateCamera2(objectPoints, imagePoints, pointCounts, imageSize, cameraMatrix, distCoeffs, rvecs, tvecs, flags
#if _CV_VERSION() >= _VERSION(2,4,0)
	, term_crit
#endif
	);
OUTPUT:
	RETVAL

void
cvComputeCorrespondEpilines(const CvMat* points, int whichImage, const CvMat* F, CvMat* lines)

void
cvConvertPointsHomogeneous(const CvMat* src, CvMat* dst)

#if _CV_VERSION() >= _VERSION(2,4,0)

void
cvTriangulatePoints(CvMat* projMatr1, CvMat* projMatr2, CvMat* projPoints1, CvMat* projPoints2, CvMat* points4D)
ALIAS: Cv::cvTriangulatePoints = 1

void
cvCorrectMatches(CvMat* F, CvMat* points1, CvMat* points2, CvMat* new_points1, CvMat* new_points2)
ALIAS: Cv::cvCorrectMatches = 1

#endif

MODULE = Cv	PACKAGE = Cv

#TBD# CvPOSITObject* cvCreatePOSITObject(CvPoint3D32f* points, int point_count)

CvStereoBMState*
cvCreateStereoBMState(int preset=CV_STEREO_BM_BASIC, int numberOfDisparities=0)


MODULE = Cv	PACKAGE = Cv::StereoBMState
void
cvFindStereoCorrespondenceBM(CvStereoBMState* state, const CvArr* left, const CvArr* right, CvArr* disparity)
C_ARGS: left, right, disparity, state
POSTCALL:
	ST(0) = ST(3);
	XSRETURN(1);

MODULE = Cv	PACKAGE = Cv::StereoBMState
# ====================
int
preFilterType(CvStereoBMState* state, int value = NO_INIT)
CODE:
	RETVAL = state->preFilterType;
	if (items == 2) state->preFilterType = value;
OUTPUT:
	RETVAL

int
preFilterSize(CvStereoBMState* state, int value = NO_INIT)
CODE:
	RETVAL = state->preFilterSize;
	if (items == 2) state->preFilterSize = value;
OUTPUT:
	RETVAL

int
preFilterCap(CvStereoBMState* state, int value = NO_INIT)
CODE:
	RETVAL = state->preFilterCap;
	if (items == 2) state->preFilterCap = value;
OUTPUT:
	RETVAL

int
SADWindowSize(CvStereoBMState* state, int value = NO_INIT)
CODE:
	RETVAL = state->SADWindowSize;
	if (items == 2) state->SADWindowSize = value;
OUTPUT:
	RETVAL

int
minDisparity(CvStereoBMState* state, int value = NO_INIT)
CODE:
	RETVAL = state->minDisparity;
	if (items == 2) state->minDisparity = value;
OUTPUT:
	RETVAL

int
numberOfDisparities(CvStereoBMState* state, int value = NO_INIT)
CODE:
	RETVAL = state->numberOfDisparities;
	if (items == 2) state->numberOfDisparities = value;
OUTPUT:
	RETVAL

int
textureThreshold(CvStereoBMState* state, int value = NO_INIT)
CODE:
	RETVAL = state->textureThreshold;
	if (items == 2) state->textureThreshold = value;
OUTPUT:
	RETVAL

int
uniquenessRatio(CvStereoBMState* state, int value = NO_INIT)
CODE:
	RETVAL = state->uniquenessRatio;
	if (items == 2) state->uniquenessRatio = value;
OUTPUT:
	RETVAL

int
speckleWindowSize(CvStereoBMState* state, int value = NO_INIT)
CODE:
	RETVAL = state->speckleWindowSize;
	if (items == 2) state->speckleWindowSize = value;
OUTPUT:
	RETVAL

int
speckleRange(CvStereoBMState* state, int value = NO_INIT)
CODE:
	RETVAL = state->speckleRange;
	if (items == 2) state->speckleRange = value;
OUTPUT:
	RETVAL

#if _CV_VERSION() >= _VERSION(2,0,0)

int
trySmallerWindows(CvStereoBMState* state, int value = NO_INIT)
CODE:
	RETVAL = state->trySmallerWindows;
	if (items == 2) state->trySmallerWindows = value;
OUTPUT:
	RETVAL

CvRect
roi1(CvStereoBMState* state, CvRect value = NO_INIT)
CODE:
	RETVAL = state->roi1;
	if (items == 2) state->roi1 = value;
OUTPUT:
	RETVAL

CvRect
roi2(CvStereoBMState* state, CvRect value = NO_INIT)
CODE:
	RETVAL = state->roi2;
	if (items == 2) state->roi2 = value;
OUTPUT:
	RETVAL

int
disp12MaxDiff(CvStereoBMState* state, int value = NO_INIT)
CODE:
	RETVAL = state->disp12MaxDiff;
	if (items == 2) state->disp12MaxDiff = value;
OUTPUT:
	RETVAL

#endif

CvMat*
preFilteredImg0(CvStereoBMState* state, CvMat* value = NO_INIT)
CODE:
	RETVAL = state->preFilteredImg0;
	if (items == 2) state->preFilteredImg0 = value;
OUTPUT:
	RETVAL bless(ST(0), "Cv::Mat::Ghost", RETVAL);

CvMat*
preFilteredImg1(CvStereoBMState* state, CvMat* value = NO_INIT)
CODE:
	RETVAL = state->preFilteredImg1;
	if (items == 2) state->preFilteredImg1 = value;
OUTPUT:
	RETVAL bless(ST(0), "Cv::Mat::Ghost", RETVAL);

CvMat*
slidingSumBuf(CvStereoBMState* state, CvMat* value = NO_INIT)
CODE:
	RETVAL = state->slidingSumBuf;
	if (items == 2) state->slidingSumBuf = value;
OUTPUT:
	RETVAL bless(ST(0), "Cv::Mat::Ghost", RETVAL);


MODULE = Cv	PACKAGE = Cv

#if _CV_VERSION() < _VERSION(2,4,0)

CvStereoGCState*
cvCreateStereoGCState(int numberOfDisparities, int maxIters)

#endif

MODULE = Cv	PACKAGE = Cv::Arr
void
cvDecomposeProjectionMatrix(const CvMat *projMatrix, CvMat *cameraMatrix, CvMat *rotMatrix, CvMat *transVect, CvMat *rotMatrX=NULL, CvMat *rotMatrY=NULL, CvMat *rotMatrZ=NULL, CvPoint3D64f *eulerAngles=NULL)

void
cvDrawChessboardCorners(CvArr* image, CvSize patternSize, CvPoint2D32f* corners, int patternWasFound)
C_ARGS: image, patternSize, corners, length(corners), patternWasFound
POSTCALL:
	XSRETURN(1);

int
cvFindChessboardCorners(const CvArr* image, CvSize patternSize, corners, int flags=CV_CALIB_CB_ADAPTIVE_THRESH)
INPUT:
	CvPoint2D32f* corners = NO_INIT
PROTOTYPE: $$\@$
PREINIT:
	int length(corners);
INIT:
	corners = (CvPoint2D32f*)alloca(sizeof(CvPoint2D32f) * patternSize.width * patternSize.height);
C_ARGS:
	image, patternSize, corners, &length(corners), flags
OUTPUT:
	RETVAL
	corners

void
cvFindExtrinsicCameraParams2(const CvMat* objectPoints, const CvMat* imagePoints, const CvMat* cameraMatrix, const CvMat* distCoeffs, CvMat* rvec, CvMat* tvec, int useExtrinsicGuess=0)
ALIAS: Cv::cvFindExtrinsicCameraParams2 = 1
CODE:
	cvFindExtrinsicCameraParams2(objectPoints, imagePoints, cameraMatrix, distCoeffs, rvec, tvec
#if _CV_VERSION() >= _VERSION(2,0,0)
		, useExtrinsicGuess
#endif
		);

int
cvFindFundamentalMat(const CvMat* points1, const CvMat* points2, CvMat* fundamentalMatrix, int  method=CV_FM_RANSAC, double param1=1., double param2=0.99, CvMat* status=NULL)
ALIAS: Cv::cvFindFundamentalMat = 1

void
cvFindHomography(const CvMat* srcPoints, const CvMat* dstPoints, CvMat* H, int method=0, double ransacReprojThreshold=3, CvMat* status=NULL)
ALIAS: Cv::cvFindHomography = 1

#if _CV_VERSION() < _VERSION(2,4,0)

MODULE = Cv	PACKAGE = Cv::StereoGCState
void
cvFindStereoCorrespondenceGC(CvStereoGCState* state, const CvArr* left, const CvArr* right, CvArr* dispLeft, CvArr* dispRight, int useDisparityGuess = 0)
C_ARGS: left, right, dispLeft, dispRight, state, useDisparityGuess

#endif

#if _CV_VERSION() >= _VERSION(2,0,0)

MODULE = Cv	PACKAGE = Cv::Arr
void
cvGetOptimalNewCameraMatrix(const CvMat* cameraMatrix, const CvMat* distCoeffs, CvSize imageSize, double alpha, CvMat* newCameraMatrix, CvSize newImageSize=cvSize(0, 0), OUT CvRect validPixROI, int centerPrincipalPoint = 0)
CODE:
	cvGetOptimalNewCameraMatrix(cameraMatrix, distCoeffs, imageSize, alpha, newCameraMatrix, newImageSize, &validPixROI
#if _CV_VERSION() >= _VERSION(2,3,0)
	, centerPrincipalPoint
#endif
	);

#endif

void
cvInitIntrinsicParams2D(const CvMat* objectPoints, const CvMat* imagePoints, const CvMat* npoints, CvSize imageSize, CvMat* cameraMatrix, double aspectRatio=1.)
ALIAS: Cv::cvInitIntrinsicParams2D = 1

void
cvInitUndistortMap(const CvMat* cameraMatrix, const CvMat* distCoeffs, CvArr* map1, CvArr* map2)
ALIAS: Cv::cvInitUndistortMap = 1

void
cvInitUndistortRectifyMap(const CvMat* cameraMatrix, const CvMat* distCoeffs, const CvMat* R, const CvMat* newCameraMatrix, CvArr* map1, CvArr* map2)
ALIAS: Cv::cvInitUndistortRectifyMap = 1

#TBD# void cvPOSIT(CvPOSITObject* posit_object, CvPoint2D32f* imagePoints, double focal_length, CvTermCriteria criteria, CvMatr32f rotationMatrix, CvVect32f translation_vector)

MODULE = Cv	PACKAGE = Cv::Arr
void
cvProjectPoints2(const CvMat* objectPoints, const CvMat* rvec, const CvMat* tvec, const CvMat* cameraMatrix, const CvMat* distCoeffs, CvMat* imagePoints, CvMat* dpdrot=NULL, CvMat* dpdt=NULL, CvMat* dpdf=NULL, CvMat* dpdc=NULL, CvMat* dpddist=NULL, double aspect_ratio=0)
POSTCALL:
	ST(0) = ST(5);
	XSRETURN(1);

void
cvReprojectImageTo3D(const CvArr* disparity, CvArr* _3dImage, const CvMat* Q, int handleMissingValues=0)
CODE:
	cvReprojectImageTo3D(disparity, _3dImage, Q
#if _CV_VERSION() >= _VERSION(2,0,0)
	, handleMissingValues
#endif
	);

void
cvRQDecomp3x3(const CvMat *M, CvMat *R, CvMat *Q, CvMat *Qx=NULL, CvMat *Qy=NULL, CvMat *Qz=NULL, CvPoint3D64f *eulerAngles=NULL)

#TBD# void cvReleasePOSITObject(CvPOSITObject** posit_object)


MODULE = Cv	PACKAGE = Cv::StereoBMState
void
cvReleaseStereoBMState(CvStereoBMState* &state)
ALIAS: DESTROY = 1
INIT:
	unbless(ST(0));


#if _CV_VERSION() < _VERSION(2,4,0)

MODULE = Cv	PACKAGE = Cv::StereoGCState
void 
cvReleaseStereoGCState(CvStereoGCState* &state)
ALIAS: DESTROY = 1
INIT:
	unbless(ST(0));

#endif

MODULE = Cv	PACKAGE = Cv::Arr
int
cvRodrigues2(const CvMat* src, CvMat* dst, CvMat* jacobian=0)


double
cvStereoCalibrate(const CvMat* objectPoints, const CvMat* imagePoints1, const CvMat* imagePoints2, const CvMat* pointCounts, CvMat* cameraMatrix1, CvMat* distCoeffs1, CvMat* cameraMatrix2, CvMat* distCoeffs2, CvSize imageSize, CvMat* R, CvMat* T, CvMat* E=0, CvMat* F=0, CvTermCriteria term_crit=cvTermCriteria(CV_TERMCRIT_ITER + CV_TERMCRIT_EPS, 30, 1e-6), int flags=CV_CALIB_FIX_INTRINSIC)
ALIAS: Cv::cvStereoCalibrate = 1
CODE:
	RETVAL = 
#if _CV_VERSION() < _VERSION(2,0,0)
	0;
#endif
	cvStereoCalibrate(objectPoints, imagePoints1, imagePoints2, pointCounts, cameraMatrix1, distCoeffs1, cameraMatrix2, distCoeffs2, imageSize, R, T, E, F, term_crit, flags);
OUTPUT:
	RETVAL

void
cvStereoRectify(const CvMat* cameraMatrix1, const CvMat* cameraMatrix2, const CvMat* distCoeffs1, const CvMat* distCoeffs2, CvSize imageSize, const CvMat* R, const CvMat* T, CvMat* R1, CvMat* R2, CvMat* P1, CvMat* P2, CvMat* Q=0, int flags=CV_CALIB_ZERO_DISPARITY, double alpha=-1, CvSize newImageSize=cvSize(0, 0), OUT CvRect roi1, OUT CvRect roi2)
ALIAS: Cv::cvStereoRectify = 1
CODE:
	cvStereoRectify(cameraMatrix1, cameraMatrix2, distCoeffs1, distCoeffs2, imageSize, R, T, R1, R2, P1, P2, Q, flags
#if _CV_VERSION() >= _VERSION(2,0,0)
		, alpha, newImageSize, &roi1, &roi2
#endif
		);

void
cvStereoRectifyUncalibrated(const CvMat* points1, const CvMat* points2, const CvMat* F, CvSize imageSize, CvMat* H1, CvMat* H2, double threshold=5)
ALIAS: Cv::cvStereoRectifyUncalibrated = 1

void
cvUndistort2(const CvArr* src, CvArr* dst, const CvMat* cameraMatrix, const CvMat* distCoeffs, const CvMat* newCameraMatrix = NULL)
CODE:
	cvUndistort2(src, dst, cameraMatrix, distCoeffs
#if _CV_VERSION() >= _VERSION(2,0,0)
		, newCameraMatrix
#endif
		);
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

void
cvUndistortPoints(const CvMat* src, CvMat* dst, const CvMat* cameraMatrix, const CvMat* distCoeffs, const CvMat* R=NULL, const CvMat* P=NULL)


MODULE = Cv	PACKAGE = Cv::StereoSGBM
# ====================

#ifdef __cplusplus
#if _CV_VERSION() >= _VERSION(2,0,0)

StereoSGBM*
StereoSGBM::new()

void
StereoSGBM::DESTROY()

void
StereoSGBM::cvFindStereoCorrespondenceSGBM(const CvMat* left, const CvMat* right, CvMat* disp)
INIT:
	Mat l(left);
	Mat r(right);
	Mat d(disp);
CODE:
	(*THIS)(l, r, d);
POSTCALL:
	ST(0) = ST(3);
	XSRETURN(1);
	
int
StereoSGBM::minDisparity(int value = NO_INIT)
CODE:
	RETVAL = THIS->minDisparity;
	if (items == 2) THIS->minDisparity = value;
OUTPUT:
	RETVAL

int
StereoSGBM::numberOfDisparities(int value = NO_INIT)
CODE:
	RETVAL = THIS->numberOfDisparities;
	if (items == 2) THIS->numberOfDisparities = value;
OUTPUT:
	RETVAL

int
StereoSGBM::SADWindowSize(int value = NO_INIT)
CODE:
	RETVAL = THIS->SADWindowSize;
	if (items == 2) THIS->SADWindowSize = value;
OUTPUT:
	RETVAL

int
StereoSGBM::preFilterCap(int value = NO_INIT)
CODE:
	RETVAL = THIS->preFilterCap;
	if (items == 2) THIS->preFilterCap = value;
OUTPUT:
	RETVAL

int
StereoSGBM::uniquenessRatio(int value = NO_INIT)
CODE:
	RETVAL = THIS->uniquenessRatio;
	if (items == 2) THIS->uniquenessRatio = value;
OUTPUT:
	RETVAL

int
StereoSGBM::P1(int value = NO_INIT)
CODE:
	RETVAL = THIS->P1;
	if (items == 2) THIS->P1 = value;
OUTPUT:
	RETVAL

int
StereoSGBM::P2(int value = NO_INIT)
CODE:
	RETVAL = THIS->P2;
	if (items == 2) THIS->P2 = value;
OUTPUT:
	RETVAL

int
StereoSGBM::speckleWindowSize(int value = NO_INIT)
CODE:
	RETVAL = THIS->speckleWindowSize;
	if (items == 2) THIS->speckleWindowSize = value;
OUTPUT:
	RETVAL

int
StereoSGBM::speckleRange(int value = NO_INIT)
CODE:
	RETVAL = THIS->speckleRange;
	if (items == 2) THIS->speckleRange = value;
OUTPUT:
	RETVAL

int
StereoSGBM::disp12MaxDiff(int value = NO_INIT)
CODE:
	RETVAL = THIS->disp12MaxDiff;
	if (items == 2) THIS->disp12MaxDiff = value;
OUTPUT:
	RETVAL

bool
StereoSGBM::fullDP(bool value = NO_INIT)
CODE:
	RETVAL = THIS->fullDP;
	if (items == 2) THIS->fullDP = value;
OUTPUT:
	RETVAL

#endif
#endif


# ============================================================
#  ml. Machine Learning
# ============================================================


# ============================================================
#  misc.
# ============================================================

MODULE = Cv	PACKAGE = Cv
# ====================

const char*
cvGetBuildInformation()

double
cvVersion()
CODE:
	RETVAL = _CV_VERSION() * 1e-6;
OUTPUT:
	RETVAL

# ====================
#  CV_[A-G]
# ====================

int
CV_ELEM_SIZE(int type)


# ====================
#  CV_[H-N]
# ====================

int
CV_IS_SET_ELEM(SV* sv)
CODE:
	void* p = INT2PTR(void*, SvIV(SvROK(sv)? (SV*)SvRV(sv) : sv));
	RETVAL = CV_IS_SET_ELEM(p);
OUTPUT:
	RETVAL

int
CV_NODE_TYPE(int type)

# ====================
#  CV_[O-U]
# ====================

# ====================
#  CV_[V-Z]
# ====================

void
CV_VERSION()
INIT:
	const int verbose = 0;
CODE:
	I32 gimme = GIMME_V; /* wantarray */
	if (gimme == G_VOID) {
		if (verbose) fprintf(stderr, "Context is Void\n");
	} else if (gimme == G_SCALAR) {
		const char *v = CV_VERSION;
		if (verbose) fprintf(stderr, "Context is Scalar\n", v);
		XPUSHs(sv_2mortal(newSVpvn(v, strlen(v))));
		XSRETURN(1);
	} else if (gimme == G_ARRAY) {
		if (verbose) fprintf(stderr, "Context is Array\n");
		XPUSHs(sv_2mortal(newSViv(CV_MAJOR_VERSION)));
		XPUSHs(sv_2mortal(newSViv(CV_MINOR_VERSION)));
		XPUSHs(sv_2mortal(newSViv(CV_SUBMINOR_VERSION)));
		XSRETURN(3);
	}

MODULE = Cv		PACKAGE = Cv
# ====================
BOOT:
	cvRedirectError(&cb_error, (VOID*)NULL, NULL);
    cvSetErrMode(1);
    cvSetErrStatus(0);
{
	HV* Cv_SIZEOF;
	struct sz {
		const char *name; int size;
	} sz[] = {
		{ "CvContour",    sizeof(CvContour) },
		{ "CvPoint",      sizeof(CvPoint) },
		{ "CvPoint3D32f", sizeof(CvPoint3D32f) },
		{ "CvSeq",        sizeof(CvSeq) },
		{ "CvSeq*",       sizeof(CvSeq*) },
		{ "CvSet",        sizeof(CvSet) },
	};
	int i;
	if (!(Cv_SIZEOF = get_hv("Cv::SIZEOF", 0))) {
		Perl_croak(aTHX_ "can't get \%Cv::SIZEOF");
	}
	for (i = 0; i < DIM(sz); i++) {
		struct sz *p = &sz[i];
		hv_store(Cv_SIZEOF, p->name, strlen(p->name), newSViv(p->size), 0);
	}
}
