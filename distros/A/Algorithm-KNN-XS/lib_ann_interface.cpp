#include "lib_ann_interface.h"

using namespace std;

LibANNInterface::LibANNInterface(std::vector< std::vector<double> >& points, string& dump, bool use_bd_tree, int bucket_size, int split_rule, int shrink_rule) {
    if (!points.size() && !dump.size())
        throw InvalidParameterValueException("either points or a tree dump must be given");

    kd_tree  = NULL;
    bd_tree  = NULL;
    data_pts = NULL;

    if (points.size()) {
        if (bucket_size < 1)
            throw InvalidParameterValueException("bucket_size must be >= 1");

        // the first element sets the dimension and set the number of availble data points
        count_data_pts = points.size();

        if (count_data_pts > 0) {
            dim = points.front().size();
        }
        else {
            dim = 0;
        }

        // allocate memory for all data points
        data_pts = annAllocPts(count_data_pts, dim);

        // fill the data_pts array
        int i = 0;

        std::vector< std::vector<double> >::iterator iter;

        for(iter = points.begin(); iter != points.end(); iter++) {
            int j = 0;
            std::vector<double>::iterator iter2;

            for(iter2 = iter->begin(); iter2 != iter->end(); iter2++) {
                data_pts[i][j] = *iter2;
                j++;
            }

            i++;
        }

        // use split rule suggested by ann as default
        ANNsplitRule ann_split_rule;

        if      (split_rule == 1) { ann_split_rule = ANN_KD_STD; }
        else if (split_rule == 2) { ann_split_rule = ANN_KD_MIDPT; }
        else if (split_rule == 3) { ann_split_rule = ANN_KD_FAIR; }
        else if (split_rule == 4) { ann_split_rule = ANN_KD_SL_MIDPT; }
        else if (split_rule == 5) { ann_split_rule = ANN_KD_SL_FAIR; }
        else                      { ann_split_rule = ANN_KD_SUGGEST; }

        // there are 2 tree types, kd and bd tree
        if (use_bd_tree) {
            // use shrink rule suggested by ann as default
            ANNshrinkRule ann_shrink_rule;

            if      (shrink_rule == 1) { ann_shrink_rule = ANN_BD_NONE; }
            else if (shrink_rule == 2) { ann_shrink_rule = ANN_BD_SIMPLE; }
            else if (shrink_rule == 3) { ann_shrink_rule = ANN_BD_CENTROID; }
            else                       { ann_shrink_rule = ANN_BD_SUGGEST; }

            // create the bdtree
            bd_tree    = new ANNbd_tree(data_pts, count_data_pts, dim, bucket_size, ann_split_rule, ann_shrink_rule);
            is_bd_tree = true;
        }
        else {
            // create the kdtree
            kd_tree    = new ANNkd_tree(data_pts, count_data_pts, dim, bucket_size, ann_split_rule);
            is_bd_tree = false;
        }
    }
    else {
        std::istringstream stream(dump);

        if (use_bd_tree) {
            // create the bdtree
            bd_tree        = new ANNbd_tree(stream);
            dim            = bd_tree->theDim();
            count_data_pts = bd_tree->nPoints();
            is_bd_tree     = true;
        }
        else {
            // create the kdtree
            kd_tree        = new ANNkd_tree(stream);
            dim            = kd_tree->theDim();
            count_data_pts = kd_tree->nPoints();
            is_bd_tree     = false;
        }
    }
}

LibANNInterface::~LibANNInterface() {
    if (bd_tree != NULL)
        delete bd_tree;

    if (kd_tree != NULL)
        delete kd_tree;

    if (data_pts != NULL)
        annDeallocPts(data_pts);

    annClose();
}

void LibANNInterface::set_annMaxPtsVisit(int max_points) {
    if (max_points < 0)
        throw InvalidParameterValueException("max_points must be >= 0");

    annMaxPtsVisit(max_points);
}

std::vector< std::vector<double> > LibANNInterface::annkSearch(std::vector<double>& query_point, int limit_neighbors, double epsilon) {
    return ann_search(query_point, limit_neighbors, epsilon, false);
}

std::vector< std::vector<double> > LibANNInterface::annkPriSearch(std::vector<double>& query_point, int limit_neighbors, double epsilon) {
    return ann_search(query_point, limit_neighbors, epsilon, true);
}

std::vector< std::vector<double> > LibANNInterface::ann_search(std::vector<double>& query_point, int limit_neighbors, double epsilon, bool use_prio_search) {
    if (limit_neighbors < 0)
        throw InvalidParameterValueException("limit_neighbors must be >= 0");

    if (limit_neighbors > count_data_pts)
        throw InvalidParameterValueException("limit_neighbors must be <= the number of points in the current tree");

    if (epsilon < 0)
        throw InvalidParameterValueException("epsilon must be >= 0");

    if (query_point.size() != dim)
        throw InvalidParameterValueException("query_point must have the same dimension as the current tree");

    if (limit_neighbors == 0)
        limit_neighbors = count_data_pts;

    std::vector< std::vector<double> > result;

    ANNidxArray nn_idx = new ANNidx[limit_neighbors];
    ANNdistArray dists = new ANNdist[limit_neighbors];
    ANNpoint query_pt  = annAllocPt(dim);

    int i = 0;
    std::vector<double>::iterator iter;

    for(iter = query_point.begin(); iter != query_point.end(); iter++) {
        query_pt[i] = *iter;
        i++;
    }

    if (is_bd_tree) {
        if (use_prio_search) {
            bd_tree->annkSearch(query_pt, limit_neighbors, nn_idx, dists, epsilon);
        }
        else {
            bd_tree->annkPriSearch(query_pt, limit_neighbors, nn_idx, dists, epsilon);
        }
    }
    else {
        if (use_prio_search) {
            kd_tree->annkSearch(query_pt, limit_neighbors, nn_idx, dists, epsilon);
        }
        else {
            kd_tree->annkPriSearch(query_pt, limit_neighbors, nn_idx, dists, epsilon);
        }
    }

    for (i = 0; i < limit_neighbors; i++) {
        if (nn_idx[i] != ANN_NULL_IDX) {
            std::vector<double> result_point;

            for (int j = 0; j < dim; j++) {
                result_point.push_back(data_pts[nn_idx[i]][j]);
            }

            result_point.push_back(dists[i]);

            result.push_back(result_point);
        }
    }

    annDeallocPt(query_pt);
    delete [] nn_idx;
    delete [] dists;

    return result;
}

std::vector< std::vector<double> > LibANNInterface::annkFRSearch(std::vector<double>& query_point, int limit_neighbors, double epsilon, double radius) {
    if (limit_neighbors < 0)
        throw InvalidParameterValueException("limit_neighbors must be >= 0");

    if (limit_neighbors > count_data_pts)
        throw InvalidParameterValueException("limit_neighbors must be <= the number of points in the current tree");

    if (epsilon < 0)
        throw InvalidParameterValueException("epsilon must be >= 0");

    if (query_point.size() != dim)
        throw InvalidParameterValueException("query_point must have the same dimension as the current tree");

    if (limit_neighbors == 0)
        limit_neighbors = count_data_pts;

    std::vector< std::vector<double> > result;

    ANNidxArray nn_idx = new ANNidx[limit_neighbors];
    ANNdistArray dists = new ANNdist[limit_neighbors];
    ANNpoint query_pt  = annAllocPt(dim);

    int i = 0;
    std::vector<double>::iterator iter;

    for(iter = query_point.begin(); iter != query_point.end(); iter++) {
        query_pt[i] = *iter;
        i++;
    }

    if (is_bd_tree) {
        bd_tree->annkFRSearch(query_pt, radius * radius, limit_neighbors, nn_idx, dists, epsilon);
    }
    else {
        kd_tree->annkFRSearch(query_pt, radius * radius, limit_neighbors, nn_idx, dists, epsilon);
    }

    for (i = 0; i < limit_neighbors; i++) {
        if (nn_idx[i] != ANN_NULL_IDX) {
            std::vector<double> result_point;

            for (int j = 0; j < dim; j++) {
                result_point.push_back(data_pts[nn_idx[i]][j]);
            }

            result_point.push_back(dists[i]);

            result.push_back(result_point);
        }
    }

    annDeallocPt(query_pt);
    delete [] nn_idx;
    delete [] dists;

    return result;
}

int LibANNInterface::annCntNeighbours(std::vector<double>& query_point, double epsilon, double radius) {
    if (epsilon < 0)
        throw InvalidParameterValueException("epsilon must be >= 0");

    if (query_point.size() != dim)
        throw InvalidParameterValueException("query_point must have the same dimension as the current tree");

    ANNpoint query_pt  = annAllocPt(dim);

    int i = 0;
    std::vector<double>::iterator iter;

    for(iter = query_point.begin(); iter != query_point.end(); iter++) {
        query_pt[i] = *iter;
        i++;
    }

    int points_nearby = 0;

    if (is_bd_tree) {
        points_nearby = bd_tree->annkFRSearch(query_pt, radius * radius, 0, NULL, NULL, epsilon);
    }
    else {
        points_nearby = kd_tree->annkFRSearch(query_pt, radius * radius, 0, NULL, NULL, epsilon);
    }

    annDeallocPt(query_pt);

    return points_nearby;
}

int LibANNInterface::theDim() {
    if (is_bd_tree) {
        return bd_tree->theDim();
    }
    else {
        return kd_tree->theDim();
    }
}

int LibANNInterface::nPoints() {
    if (is_bd_tree) {
        return bd_tree->nPoints();
    }
    else {
        return kd_tree->nPoints();
    }
}

std::string LibANNInterface::Print(bool print_points) {
    std::ostringstream stream;
    ANNbool ann_print_points;

    if (print_points) {
        ann_print_points = ANNtrue;
    }
    else {
        ann_print_points = ANNfalse;
    }

    if (is_bd_tree) {
        bd_tree->Print(ann_print_points, stream);
    }
    else {
        kd_tree->Print(ann_print_points, stream);
    }

    return stream.str();
}

std::string LibANNInterface::Dump(bool print_points) {
    std::ostringstream stream;
    ANNbool ann_print_points;

    if (print_points) {
        ann_print_points = ANNtrue;
    }
    else {
        ann_print_points = ANNfalse;
    }

    if (is_bd_tree) {
        bd_tree->Dump(ann_print_points, stream);
    }
    else {
        kd_tree->Dump(ann_print_points, stream);
    }

    return stream.str();
}

std::vector<double> LibANNInterface::getStats() {
    std::vector<double> result;

    ANNkdStats* stats = new ANNkdStats;

    if (is_bd_tree) {
        bd_tree->getStats(*stats);
    }
    else {
        kd_tree->getStats(*stats);
    }

    result.push_back((double) stats->dim); // dimension of space
    result.push_back((double) stats->n_pts); // number of points
    result.push_back((double) stats->bkt_size); // bucket size
    result.push_back((double) stats->n_lf); // number of leaves
    result.push_back((double) stats->n_tl); // number of trivial leaves
    result.push_back((double) stats->n_spl); // number of splitting nodes
    result.push_back((double) stats->n_shr); // number of shrinking nodes (bd-trees only)
    result.push_back((double) stats->depth); // depth of tree
    result.push_back(stats->avg_ar); // average leaf aspect ratio

    delete stats;

    return result;
}
