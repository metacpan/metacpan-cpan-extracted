#include <stdio.h>
#include <xgboost/c_api.h>

int main() {
    
    DMatrixHandle dtrain;
    DMatrixHandle dtest;
    // Agaricus files can be found in XGBoost demo/data directory
    // Original source: http://archive.ics.uci.edu/ml/datasets/mushroom
    XGDMatrixCreateFromFile("agaricus.txt.test", 0, &dtest);
    XGDMatrixCreateFromFile("agaricus.txt.train", 0, &dtrain);
    DMatrixHandle cache[] = {dtrain};
    BoosterHandle booster;
    XGBoosterCreate(cache, 1, &booster);
    for (int iter = 0; iter < 11; iter++) {
        XGBoosterUpdateOneIter(booster, iter, dtrain);
    }

    bst_ulong out_len;
    const float *out_result;
    XGBoosterPredict(booster, dtest, 0, 0, &out_len, &out_result);
   
    printf("Length: %ld\n", out_len);
    for (int output = 0; output < out_len; output++) {
        printf("%f\n", out_result[output]);
    }

}
