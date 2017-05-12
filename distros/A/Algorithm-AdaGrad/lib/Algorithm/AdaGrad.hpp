#if !defined(ADAGRAD_HPP_)
#define ADAGRAD_HPP_

#include <cmath>
#include <cstddef>
#include <iostream>

class AdaGrad {
public:
    AdaGrad() : eta_(1.0), sumOfGradient_(0.0), numOfGradient_(0), current_(0.0) {

    }

    AdaGrad(double eta) : eta_(eta), sumOfGradient_(0.0), numOfGradient_(0), current_(0.0) {
    }

    virtual ~AdaGrad() {
    }

    bool update(double gradient) {
        ++numOfGradient_;
        double gradSquare = gradient * gradient;
        sumOfGradient_ += gradSquare;
        current_ = current_ - (eta_ / sqrt(1 + sumOfGradient_) * gradient);
        return current_ > 0 ? true : false;
    }

    double classify(double weight) const {
        return current_ * weight;
    }

    double getNumOfGradient() const {
        return numOfGradient_;
    }

    double getValue() const {
        return current_;
    }

    void save(std::ostream& os) const {
        os.write(reinterpret_cast<const char*>(&eta_), sizeof(double));
        os.write(reinterpret_cast<const char*>(&sumOfGradient_), sizeof(double));
        os.write(reinterpret_cast<const char*>(&numOfGradient_), sizeof(size_t));
        os.write(reinterpret_cast<const char*>(&current_), sizeof(double));
    }

    void load(std::istream& is) {
        is.read(reinterpret_cast<char*>(&eta_), sizeof(double));
        is.read(reinterpret_cast<char*>(&sumOfGradient_), sizeof(double));
        is.read(reinterpret_cast<char*>(&numOfGradient_), sizeof(size_t));
        is.read(reinterpret_cast<char*>(&current_), sizeof(double));
    }

private:
    double eta_;
    double sumOfGradient_;
    size_t numOfGradient_;
    double current_;

};

#endif /* !defined(ADAGRAD_HPP_) */
