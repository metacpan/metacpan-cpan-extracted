/* -*- mode: text; coding: utf-8; tab-width: 4 -*- */

#include "Cv.inc"

MODULE = Cv::Histogram		PACKAGE = Cv::Histogram

# ============================================================
#  imgproc. Image Processing: Histograms
# ============================================================

int
type(CvHistogram* hist)
CODE:
	RETVAL = hist->type;
OUTPUT:
	RETVAL

SV*
bins(CvHistogram* hist)
CODE:
	ST(0) = sv_newmortal();
	if (CV_IS_MATND(hist->bins)) {
		sv_setref_pv(ST(0), "Cv::MatND::Ghost", hist->bins);
	} else if (CV_IS_SPARSE_MAT(hist->bins)) {
		sv_setref_pv(ST(0), "Cv::SparseMat::Ghost", hist->bins);
	} else {
		Perl_croak(aTHX_ "Cv::Histogram::bins: unknown array type"); // XXXXX
	}

AV*
ranges(CvHistogram* hist)
INIT:
	int size[CV_MAX_DIM];
	int dims = cvGetDims(hist->bins, size);
CODE:
	RETVAL = newAV();
	if (hist->type & CV_HIST_RANGES_FLAG) { int i, j;
		for (i = 0; i < dims; i++) {
			AV* av = newAV();
			if (hist->thresh2) {
				for (j = 0; j <= size[i]; j++) {
					av_push(av, newSVnv(hist->thresh2[i][j]));
				}
			} else {
				for (j = 0; j <= size[i]; j++) {
					av_push(av, newSVnv(hist->thresh[i][j]));
				}
			}
			av_push(RETVAL, newRV_inc(sv_2mortal((SV*)av)));
		}
	}
OUTPUT:
	RETVAL

void
cvCalcBackProject(IplImage** images, CvArr* back_project, const CvHistogram* hist)
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

void
cvCalcBackProjectPatch(IplImage** images, CvArr* dst, CvSize patch_size, CvHistogram* hist, int method, double factor)
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

void
cvCalcHist(IplImage** image, CvHistogram* hist, int accumulate=0, const CvArr* mask=NULL)
POSTCALL:
	ST(0) = ST(1);
 	XSRETURN(1);

void
cvCalcProbDensity(const CvHistogram* hist1, const CvHistogram* hist2, CvHistogram* dst_hist, double scale=255)
POSTCALL:
	XSRETURN(1);

void
cvClearHist(CvHistogram* hist)
POSTCALL:
	XSRETURN(1);

double
cvCompareHist(const CvHistogram* hist1, const CvHistogram* hist2, int method)

void
cvCopyHist(const CvHistogram* src, IN_OUT CvHistogram* dst)
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);

CvHistogram*
cvCreateHist(int* sizes, int type, float** ranges=NULL, int uniform=1)
CODE:
	RETVAL = cvCreateHist(length(sizes), sizes, type, ranges, uniform);
#if CV_MAJOR_VERSION < 2
	if (uniform) RETVAL->type |= CV_HIST_UNIFORM_FLAG;
	if (ranges)  RETVAL->type |= CV_HIST_RANGES_FLAG;
#endif
OUTPUT:
	RETVAL

#legacy# double cvGetHistValue_1D(CvHistogram* hist, int idx0)
#legacy# double cvGetHistValue_2D(CvHistogram* hist, int idx0, int idx1)
#legacy# double cvGetHistValue_3D(CvHistogram* hist, int idx0, int idx1, int idx2)
#legacy# double cvGetHistValue_nD(CvHistogram* hist, int* idx)

void
cvGetMinMaxHistValue(const CvHistogram* hist, OUT float min_value, OUT float max_value, OUT int min_idx = NO_INIT, OUT int max_idx = NO_INIT)

#TBD# CvHistogram* cvMakeHistHeaderForArray(int dims, int* sizes, CvHistogram* hist, float* data, float** ranges=NULL, int uniform=1)

void
cvNormalizeHist(CvHistogram* hist, double factor)
POSTCALL:
	XSRETURN(1);

#legacy# float cvQueryHistValue_1D(CvHistogram* hist, int idx0)
#legacy# float cvQueryHistValue_2D(CvHistogram* hist, int idx0, int idx1)
#legacy# float cvQueryHistValue_3D(CvHistogram* hist, int idx0, int idx1, int idx2)
#legacy# float cvQueryHistValue_nD(CvHistogram* hist, int* idx)

void
cvReleaseHist(CvHistogram* &hist)

void
cvSetHistBinRanges(CvHistogram* hist, float** ranges, int uniform=1)
POSTCALL:
	XSRETURN(1);

void
cvThreshHist(CvHistogram* hist, double threshold)
POSTCALL:
	XSRETURN(1);

void
cvCalcPGH(const CvSeq* contour, CvHistogram* hist)
POSTCALL:
	ST(0) = ST(1);
	XSRETURN(1);
