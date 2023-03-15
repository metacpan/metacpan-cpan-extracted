int array_reverse(int a[], int len) {
    int tmp, i;
    int ret = 0;
    for (i = 0; i < len / 2; i++) {
        ret += a[i];
        tmp = a[i];
        a[i] = a[len - i - 1];
        a[len - i - 1] = tmp;
    }
    return ret;
}

int array_reverse10(int a[10]) {
    return array_reverse(a, 10);
}
